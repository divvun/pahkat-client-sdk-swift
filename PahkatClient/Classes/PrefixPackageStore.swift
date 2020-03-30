import Foundation

public class PrefixPackageStore: NSObject {
    private let handle: UnsafeRawPointer
    
    public static func create(path prefixPath: String) throws -> PrefixPackageStore {
        let handle = prefixPath.withRustSlice {
            pahkat_prefix_package_store_create($0, errCallback)
        }
        try assertNoError()
        return PrefixPackageStore(handle: handle!!)
    }
    
    public static func open(path prefixPath: String) throws -> PrefixPackageStore {
        let handle = prefixPath.withRustSlice {
            pahkat_prefix_package_store_open($0, errCallback)
        }
        try assertNoError()
        return PrefixPackageStore(handle: handle!!)
    }
    
//    public func config() throws -> StoreConfig {
//        let ptr = pahkat_prefix_package_store_config(handle, errCallback)
//        try assertNoError()
//        return StoreConfig(handle: ptr!)
//    }
    
    lazy var urlSession: URLSession = {
        let bundle = Bundle.main.bundleIdentifier ?? "app"
        
#if os(iOS)
        let config = URLSessionConfiguration.background(withIdentifier: "\(bundle).PahkatClient")
        config.waitsForConnectivity = true
        config.sessionSendsLaunchEvents = true
#else
        let config = URLSessionConfiguration.default
#endif
        
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    internal init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    public func resolvePackage(packageKey: PackageKey) throws -> Package? {
        let cJsonPackage = packageKey.rawValue.withRustSlice { cPackageKey in
            pahkat_prefix_package_store_find_package_by_key(handle, cPackageKey, errCallback)
        }
        try assertNoError()
        defer { pahkat_str_free(cJsonPackage!) }
        let data = String.from(slice: cJsonPackage!).data(using: .utf8)!
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
        
        if #available(OSX 10.13, iOS 11.0, *) {
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
        let slice = packageKey.rawValue.withRustSlice { cPackageKey in
            installerPath.withRustSlice { cPath in
                pahkat_prefix_package_store_import(handle, cPackageKey, cPath, errCallback)
            }
        }
        try assertNoError()
//        defer { pahkat_str_free(cPath) }
        
        return String(bytes: slice!!, encoding: .utf8)!
    }
    
    public func clearCache() throws {
        pahkat_prefix_package_store_clear_cache(handle, errCallback)
        try assertNoError()
    }
    
    public func refreshRepos() throws {
        pahkat_prefix_package_store_refresh_repos(handle, errCallback)
        try assertNoError()
    }
    
    public func forceRefreshRepos() throws {
        pahkat_prefix_package_store_force_refresh_repos(handle, errCallback)
        try assertNoError()
    }
    
//    public func repoIndexes() throws -> [RepositoryIndex] {
//        let repoIndexsCStr = pahkat_prefix_package_store_repo_indexes(handle, errCallback)
//        try assertNoError()
//        defer { pahkat_str_free(repoIndexsCStr) }
//        
//        let jsonDecoder = JSONDecoder()
//                
//        let reposStr = String(cString: repoIndexsCStr!)
//        let reposJson = reposStr.data(using: .utf8)!
//        
//        let repos = try jsonDecoder.decode([RepositoryIndex].self, from: reposJson)
//        return repos
//    }
    
    public func allStatuses(repo: RepoRecord) throws -> [String: PackageStatusResponse] {
        let repoRecordStr = String(data: try JSONEncoder().encode(repo), encoding: .utf8)!
        
        let statusesCStr = repoRecordStr.withRustSlice { cStr in
            pahkat_prefix_package_store_all_statuses(handle, cStr, errCallback)
        }
        try assertNoError()
        defer { pahkat_str_free(statusesCStr!) }
        
        let statusesData = String.from(slice: statusesCStr!).data(using: .utf8)!
        let statuses = try JSONDecoder().decode(
            [String: PackageInstallStatus].self,
            from: statusesData)
        
        return statuses.mapValues { status in
            PackageStatusResponse(status: status, target: InstallerTarget.system)
        }
    }
    
    public func transaction(actions: [TransactionAction<Empty>]) throws -> PackageTransaction<Empty> {
        print("Encoding: \(actions)")
        let jsonActions = try JSONEncoder().encode(actions)
        print("Encoded: \(jsonActions)")
        let ptr = String(data: jsonActions, encoding: .utf8)!.withRustSlice { cStr in
            pahkat_prefix_transaction_new(handle, cStr, errCallback)
        }
        try assertNoError()
        return PackageTransaction(handle: ptr!!, actions: actions, rawProcessFunc: .prefix)
    }
}

#if os(iOS)
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
