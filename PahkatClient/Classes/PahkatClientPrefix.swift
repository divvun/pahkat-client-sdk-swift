import Foundation


public class PrefixPackageStore: NSObject {
    private let handle: UnsafeRawPointer
    
    public static func create(path prefixPath: String) throws -> PrefixPackageStore {
        let handle = prefixPath.withCString {
            pahkat_prefix_package_store_create($0, pahkat_client_err_callback)
        }
        try assertNoError()
        return PrefixPackageStore(handle: handle!)
    }
    
    public static func open(path prefixPath: String) throws -> PrefixPackageStore {
        let handle = prefixPath.withCString {
            pahkat_prefix_package_store_open($0, pahkat_client_err_callback)
        }
        try assertNoError()
        return PrefixPackageStore(handle: handle!)
    }
    
    public func config() throws -> StoreConfig {
        let ptr = pahkat_prefix_package_store_config(handle, pahkat_client_err_callback)
        try assertNoError()
        return StoreConfig(handle: ptr!)
    }
    
    private lazy var urlSession: URLSession = {
        let bundle = Bundle.main.bundleIdentifier ?? "app"
        let config = URLSessionConfiguration.default
        
#if TARGET_OS_IPHONE
        let config = URLSessionConfiguration.background(withIdentifier: "\(bundle).PahkatClient")
        config.waitsForConnectivity = true
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
#endif
        
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    internal init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    public func resolvePackage(packageKey: PackageKey) throws -> Package? {
        let cJsonPackage = packageKey.rawValue.withCString { cPackageKey in
            pahkat_prefix_package_store_resolve_package(handle, cPackageKey, pahkat_client_err_callback)
        }
        try assertNoError()
        defer { pahkat_str_free(cJsonPackage) }
        let data = String(cString: cJsonPackage!).data(using: .utf8)!
        return try JSONDecoder().decode(Package.self, from: data)
    }
    
    private var downloadCallbacks = [PackageKey: (Error?, String?) -> ()]()
    
    @discardableResult
    public func download(packageKey: PackageKey, completion: ((Error?, String?) -> ())? = nil) throws -> URLSessionDownloadTask {
        print("DOWNLOAD")
        guard let package = try self.resolvePackage(packageKey: packageKey) else {
            throw PahkatClientError(message: "No package found for \(packageKey.rawValue)")
        }
        
        guard let installer = package.tarballInstaller else {
            throw PahkatClientError(message: "No tarball installer for \(packageKey.rawValue)")
        }
        
        let task = self.urlSession.downloadTask(with: installer.url)
        task.taskDescription = packageKey.rawValue
        
        if #available(OSX 10.13, iOS 9.0, *) {
            task.countOfBytesClientExpectsToReceive = Int64(installer.size)
        } else {
            // Do nothing.
        }
        
        if let completion = completion {
            downloadCallbacks[packageKey] = completion
        }
        
        print("RESUME \(installer.url)")
        
        task.resume()
        return task
    }
    
    func `import`(packageKey: PackageKey, installerPath: String) throws -> String {
        let cPath = packageKey.rawValue.withCString { cPackageKey in
            installerPath.withCString { cPath in
                pahkat_prefix_package_store_import(handle, cPackageKey, cPath, pahkat_client_err_callback)
            }
        }
        try assertNoError()
        defer { pahkat_str_free(cPath) }
        
        return String(cString: cPath!)
    }
    
    public func clearCache() throws {
        pahkat_prefix_package_store_clear_cache(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    public func refreshRepos() throws {
        pahkat_prefix_package_store_refresh_repos(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    public func forceRefreshRepos() throws {
        pahkat_prefix_package_store_force_refresh_repos(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    public func repoIndexes() throws -> [RepositoryIndex] {
        let repoIndexsCStr = pahkat_prefix_package_store_repo_indexes(handle, pahkat_client_err_callback)
        try assertNoError()
        defer { pahkat_str_free(repoIndexsCStr) }
        
        let jsonDecoder = JSONDecoder()
                
        let reposStr = String(cString: repoIndexsCStr!)
        let reposJson = reposStr.data(using: .utf8)!
        
        let repos = try jsonDecoder.decode([RepositoryIndex].self, from: reposJson)
        return repos
    }
    
    public func transaction(actions: [TransactionAction<Empty>]) throws -> PackageTransaction {
        print("Encoding: \(actions)")
        let jsonActions = try JSONEncoder().encode(actions)
        print("Encoded: \(jsonActions)")
        let ptr = String(data: jsonActions, encoding: .utf8)!.withCString { cStr in
            pahkat_prefix_transaction_new(handle, cStr, pahkat_client_err_callback)
        }
        try assertNoError()
        return PackageTransaction(handle: ptr!)
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

private var transactionProcessCallbacks = [UInt32: PackageTransactionDelegate]()

private let transactionProcessHandler: @convention(c) (UInt32, UnsafePointer<Int8>, UInt32) -> Void = { tag, cPackageKey, cEvent in
    
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


#if TARGET_OS_IPHONE
extension PrefixPackageStore: URLSessionDelegate {
    @available(iOS 9.0, *)
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // TODO
    }
}
#endif

extension PrefixPackageStore: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("\(downloadTask.packageKey): \(fileOffset)/\(expectedTotalBytes)")
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let packageKey = task.packageKey else {
            print(error)
            print("Unknown download task, ignoring.")
            print(task)
            return
        }
        
        print(error)
        defer {
            self.downloadCallbacks.removeValue(forKey: packageKey)
        }
        
        self.downloadCallbacks[packageKey]?(error, nil)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let packageKey = downloadTask.packageKey else {
            print("Unknown download task, ignoring.")
            print(downloadTask)
            return
        }

        defer {
            self.downloadCallbacks.removeValue(forKey: packageKey)
        }
        
        print("Path: \(location.path)")
        
        do {
            let path = try self.import(packageKey: packageKey, installerPath: location.path)
            print(path)
            self.downloadCallbacks[packageKey]?(nil, path)
        } catch {
            print(error)
            self.downloadCallbacks[packageKey]?(error, nil)
        }
    }
}

fileprivate extension URLSessionTask {
    var packageKey: PackageKey? {
        guard let s = self.taskDescription else { return nil }
        guard let url = URL(string: s) else { return nil }
        return PackageKey(from: url)
    }
}
