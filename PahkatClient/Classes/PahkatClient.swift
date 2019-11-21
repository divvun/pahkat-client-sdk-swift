import Foundation

public struct PahkatClientError: Error {
    public let message: String
    public let stack: [String]
    
    init(message: String) {
        self.message = message
        stack = Thread.callStackSymbols
    }
}

public struct SliceIterator: IteratorProtocol {
    private let slice: rust_slice_t
    private var current: Int = 0
    
    public typealias Element = UInt8
    
    public mutating func next() -> UInt8? {
        if current >= self.slice.len {
            return nil
        }
        
        let v = self.slice.data!
            .assumingMemoryBound(to: UInt8.self)
            .advanced(by: current)
            .pointee
        
        self.current += 1
        
        return v
    }
    
    init(_ slice: rust_slice_t) {
        self.slice = slice
    }
}

extension rust_slice_t: Sequence {
    public typealias Element = UInt8
    public typealias Iterator = SliceIterator
    
    public var underestimatedCount: Int {
        return Int(self.len)
    }
    
    public func makeIterator() -> SliceIterator {
        return SliceIterator(self)
    }
}

extension rust_slice_t: Collection {
    public typealias Index = UInt
    
    public var startIndex: UInt { return 0 }
    public var endIndex: UInt { return self.len }
    
    public func index(after i: UInt) -> UInt {
        return i + 1
    }
    
    public subscript(position: UInt) -> UInt8 {
        return self.data!
            .assumingMemoryBound(to: UInt8.self)
            .advanced(by: Int(position))
            .pointee
    }
}

extension PahkatClientError: CustomDebugStringConvertible {
    public var debugDescription: String {
        let msg = "PahkatClientError: \(message)\n  Stacktrace:\n"
        return msg + stack.joined(separator: "\n")
    }
}

private var pahkat_client_err: PahkatClientError? = nil

internal let pahkat_client_err_callback: @convention(c) (UnsafePointer<Int8>) -> Void = { cStr in
    let error = String(cString: cStr)
    pahkat_client_err = PahkatClientError(message: error)
}

internal func assertNoError() throws {
    if let err = pahkat_client_err {
        pahkat_client_err = nil
        throw err
    }
}

public class StoreConfig {
    private let handle: UnsafeRawPointer
    
    init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    public func configPath() throws -> String {
        let slice = pahkat_store_config_config_path(handle, pahkat_client_err_callback)
        // TODO: free
        try assertNoError()
        return String(bytes: slice, encoding: .utf8)!
    }
    
    public func set(uiSetting key: String, value: String?) throws {
        key.withCString { key in
            if let value = value {
                value.withCString { value in
                    pahkat_store_config_set_ui_value(handle, key, value, pahkat_client_err_callback)
                }
            } else {
                pahkat_store_config_set_ui_value(handle, key, nil, pahkat_client_err_callback)
            }
        }
        
        try assertNoError()
    }
    
    public func get(uiSetting key: String) throws -> String? {
        let cValue = key.withCString { key in
            pahkat_store_config_ui_value(handle, key, pahkat_client_err_callback)
        }
        
        try assertNoError()
        
        if let cValue = cValue {
            defer { pahkat_str_free(cValue) }
            return String(cString: cValue)
        } else {
            return nil
        }
    }
    
    public func repos() throws -> [RepoRecord] {
        let cStr = pahkat_store_config_repos(handle, pahkat_client_err_callback)
        try assertNoError()
        
        defer { pahkat_str_free(cStr) }
        let data = String(cString: cStr!).data(using: .utf8)!
        
//        log.debug("Decode repos")
        return try! JSONDecoder().decode([RepoRecord].self, from: data)
    }
    
    public func set(repos: [RepoRecord]) throws {
        let json = try! JSONEncoder().encode(repos)
        String(data: json, encoding: .utf8)!.withCString { cStr in
            pahkat_store_config_set_repos(handle, cStr, pahkat_client_err_callback)
        }
        try assertNoError()
    }
    
    public func setCacheBase(url: URL) throws {
        url.absoluteString.withCString { cStr in
            pahkat_store_config_set_cache_base_url(handle, cStr, pahkat_client_err_callback)
        }
        try assertNoError()
    }
    
    public func setCacheBase(path: String) throws {
        let url = URL(fileURLWithPath: path)
        return try setCacheBase(url: url)
    }

    public func cacheBaseURL() throws -> URL {
        let cStr = pahkat_store_config_cache_base_url(handle, pahkat_client_err_callback)
        try assertNoError()
        defer { pahkat_str_free(cStr) }
        
        // This cannot fail as the Rust contract guarantees a real pointer if no error
        let urlString = String(cString: cStr!)
        
        // This cannot fail because the Rust contract guarantees a URL
        return URL(string: urlString)!
    }
}

public struct RepoRecord: Codable, Equatable, Hashable {
    public let url: URL
    public let channel: Repository.Channels
    
    public init(url: URL, channel: Repository.Channels) {
        self.url = url
        self.channel = channel
    }
}

private var nextPackageTransactionId: UInt32 = 1

enum RawProcessFunc {
    case macos
    case prefix
    
    func invoke(handle: UnsafeRawPointer, id: UInt32) {
        switch self {
        case .macos:
            pahkat_macos_transaction_process(handle, id, transactionProcessHandler, pahkat_client_err_callback)
        case .prefix:
            pahkat_prefix_transaction_process(handle, id, transactionProcessHandler, pahkat_client_err_callback)
        }
    }
}

public class PackageTransaction<T: Codable> {
    private let handle: UnsafeRawPointer
    public let actions: [TransactionAction<T>]
    private let rawProcessFunc: RawProcessFunc
    
    init(handle: UnsafeRawPointer, actions: [TransactionAction<T>], rawProcessFunc: RawProcessFunc) {
        self.handle = handle
        self.actions = actions
        self.rawProcessFunc = rawProcessFunc
    }

    public func process(delegate: PackageTransactionDelegate) {
        defer { nextPackageTransactionId += 1 }
        
        let id = nextPackageTransactionId
        transactionProcessCallbacks[id] = delegate
        defer {
            transactionProcessCallbacks.removeValue(forKey: id)
        }
        
        self.rawProcessFunc.invoke(handle: handle, id: id)
        
        do {
            try assertNoError()
        } catch {
            delegate.transactionDidError(id, packageKey: nil, error: error)
        }
        
        delegate.transactionDidComplete(id)
    }
}

public struct Empty: Codable, Equatable, Hashable {
    public static let instance = Empty()
    private init() {}
    public init(from decoder: Decoder) throws {
        self = Empty.instance
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

public enum PackageTransactionEvent: UInt32, Codable {
    case notStarted = 0
    case uninstalling = 1
    case installing = 2
    case completed = 3
    case error = 4
}

public protocol PackageTransactionDelegate: class {
    func isTransactionCancelled(_ id: UInt32) -> Bool
    
    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey)
    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey)
    func transactionDidComplete(_ id: UInt32)
    func transactionDidCancel(_ id: UInt32)
    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?)
    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32)
}

internal var transactionProcessCallbacks = [UInt32: PackageTransactionDelegate]()

internal let transactionProcessHandler: @convention(c) (UInt32, UnsafePointer<Int8>, UInt32) -> UInt8 = { tag, cPackageKey, cEvent in
    guard let delegate = transactionProcessCallbacks[tag] else {
        // TODO: log
        return 0
    }
    
    if delegate.isTransactionCancelled(tag) {
        delegate.transactionDidCancel(tag)
        transactionProcessCallbacks.removeValue(forKey: tag)
        return 0
    }
    
    let packageKey = PackageKey(from: URL(string: String(cString: cPackageKey))!)
    
    guard let event = PackageTransactionEvent(rawValue: cEvent) else {
        delegate.transactionDidUnknownEvent(tag, packageKey: packageKey, event: cEvent)
        return delegate.isTransactionCancelled(tag) ? 0 : 1
    }
    
    switch event {
    case .installing:
        delegate.transactionWillInstall(tag, packageKey: packageKey)
    case .uninstalling:
        delegate.transactionWillUninstall(tag, packageKey: packageKey)
    case .error:
        delegate.transactionDidError(tag, packageKey: packageKey, error: nil)
        transactionProcessCallbacks.removeValue(forKey: tag)
    case .completed:
        delegate.transactionDidComplete(tag)
        transactionProcessCallbacks.removeValue(forKey: tag)
    case .notStarted:
        break
    }
    
    return delegate.isTransactionCancelled(tag) ? 0 : 1
}

public protocol PackageDownloadDelegate: class {
    var isDownloadCancelled: Bool { get }
    
    func downloadDidProgress(_ packageKey: PackageKey, current: UInt64, maximum: UInt64)
    func downloadDidComplete(_ packageKey: PackageKey, path: String)
    func downloadDidCancel(_ packageKey: PackageKey)
    func downloadDidError(_ packageKey: PackageKey, error: Error)
}

internal var downloadProcessCallbacks = [PackageKey: PackageDownloadDelegate]()

internal let downloadProcessHandler: @convention(c) (UnsafePointer<CChar>, UInt64, UInt64) -> UInt8 = { cPackageKey, current, maximum in
    
    let packageKey = PackageKey(from: URL(string: String(cString: cPackageKey))!)
    
    guard let delegate = downloadProcessCallbacks[packageKey] else {
        // TODO: log
        return 0
    }

    delegate.downloadDidProgress(packageKey, current: current, maximum: maximum)
    return delegate.isDownloadCancelled ? 0 : 1
}
