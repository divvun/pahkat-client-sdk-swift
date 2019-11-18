import Foundation

public struct PahkatClientError: Error {
    public let message: String
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
    
    func set(cachePath: String) throws {
        fatalError("unimplemented")
//        let cStr = cachePath.cString(using: .utf8)!
//        pahkat_store_config_set_cache_base_path(handle, cStr, pahkat_client_err_callback)
//        try assertNoError()
    }

    func cachePath() throws -> String {
        fatalError("unimplemented")
//        let cStr = pahkat_store_config_cache_base_path(handle, pahkat_client_err_callback)
//        try assertNoError()
//        defer { pahkat_str_free(cStr) }
//        let path = String(cString: cStr!)
//        return path
    }
}

public struct RepoRecord: Codable, Equatable, Hashable {
    let url: URL
    let channel: Repository.Channels
    
    public init(url: URL, channel: Repository.Channels) {
        self.url = url
        self.channel = channel
    }
}

public class PackageTransaction {
    private static var nextId: UInt32 = 1
    
    private let handle: UnsafeRawPointer
    
    init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    public func process(delegate: PackageTransactionDelegate) {
        defer { PackageTransaction.nextId += 1 }
        
        let id = PackageTransaction.nextId
        transactionProcessCallbacks[id] = delegate
        defer {
            transactionProcessCallbacks.removeValue(forKey: id)
        }
        
        pahkat_prefix_transaction_process(handle, id, transactionProcessHandler, pahkat_client_err_callback)
        
        do {
            try assertNoError()
        } catch {
            delegate.transactionDidError(id, error: error)
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
    func transactionDidEvent(_ id: UInt32, packageKey: PackageKey, event: PackageTransactionEvent)
    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32)
    func transactionDidComplete(_ id: UInt32)
    func transactionDidError(_ id: UInt32, error: Error)
}

internal var transactionProcessCallbacks = [UInt32: PackageTransactionDelegate]()

internal let transactionProcessHandler: @convention(c) (UInt32, UnsafePointer<Int8>, UInt32) -> Void = { tag, cPackageKey, cEvent in
    
    guard let delegate = transactionProcessCallbacks[tag] else {
        return
    }
    
    let packageKey = PackageKey(from: URL(string: String(cString: cPackageKey))!)
    guard let event = PackageTransactionEvent(rawValue: cEvent) else {
        delegate.transactionDidUnknownEvent(tag, packageKey: packageKey, event: cEvent)
        return
    }
    
    delegate.transactionDidEvent(tag, packageKey: packageKey, event: event)
}
