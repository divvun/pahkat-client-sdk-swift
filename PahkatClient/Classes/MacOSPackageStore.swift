#if os(macOS)
import Foundation

public class MacOSPackageStore: PackageStore {
    typealias Target = InstallerTarget
    
    let jsonDecoder = JSONDecoder()
    
    static public func `default`() -> MacOSPackageStore {
        let handle = pahkat_macos_package_store_default()
        return MacOSPackageStore(handle: handle)
    }
    
    static public func create(path: String) throws -> MacOSPackageStore {
        let handle = path.withCString {
            pahkat_macos_package_store_new($0, pahkat_client_err_callback)
        }
        try assertNoError()
        return MacOSPackageStore(handle: handle!)
    }
    
    static public func load(path: String) throws -> MacOSPackageStore {
        let handle = path.withCString {
            pahkat_macos_package_store_load($0, pahkat_client_err_callback)
        }
        try assertNoError()
        return MacOSPackageStore(handle: handle!)
    }
    
    private let handle: UnsafeRawPointer
    
    private init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    public func config() throws -> StoreConfig {
        let ptr = pahkat_macos_package_store_config(handle, pahkat_client_err_callback)
        try assertNoError()
        return StoreConfig(handle: ptr!)
    }
    
    public func download(packageKey: PackageKey, delegate: PackageDownloadDelegate) {
        downloadProcessCallbacks[packageKey] = delegate
        
        DispatchQueue.global(qos: .userInitiated).async {
            let slice = packageKey.rawValue.withCString { cPackageKey in
                pahkat_macos_package_store_download(self.handle, cPackageKey, downloadProcessHandler, pahkat_client_err_callback)
            }
            
            if delegate.isDownloadCancelled {
                delegate.downloadDidCancel(packageKey)
                downloadProcessCallbacks.removeValue(forKey: packageKey)
                return
            }
            
            do {
                try assertNoError()
            } catch {
                delegate.downloadDidError(packageKey, error: error)
                downloadProcessCallbacks.removeValue(forKey: packageKey)
                return
            }
            
            // TODO: free cPath
            let path = String(bytes: slice, encoding: .utf8)!
            delegate.downloadDidComplete(packageKey, path: path)
            downloadProcessCallbacks.removeValue(forKey: packageKey)
        }
    }
    
    func `import`(packageKey: PackageKey, installerPath: String) throws -> String {
        let slice = packageKey.rawValue.withCString { cPackageKey in
            installerPath.withCString { cPath in
                pahkat_macos_package_store_import(handle, cPackageKey, cPath, pahkat_client_err_callback)
            }
        }
        try assertNoError()
//        defer { pahkat_str_free(cPath) }
        
        return String(bytes: slice, encoding: .utf8)!
    }
    
    public func clearCache() throws {
        pahkat_macos_package_store_clear_cache(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    public func refreshRepos() throws {
        pahkat_macos_package_store_refresh_repos(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    public func forceRefreshRepos() throws {
        pahkat_macos_package_store_force_refresh_repos(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    public func repoIndexes(withStatuses: Bool = true) throws -> [RepositoryIndex] {
        let repoIndexsCStr = pahkat_macos_package_store_repo_indexes(handle, pahkat_client_err_callback)
        try assertNoError()
        defer { pahkat_str_free(repoIndexsCStr) }
                
        let reposStr = String(cString: repoIndexsCStr!)
        let reposJson = reposStr.data(using: .utf8)!
        
        let repos = try jsonDecoder.decode([RepositoryIndex].self, from: reposJson)
        if withStatuses {
//            return repos.map { $0.statuses = try allStatuses(repo: RepoRecord(url: $0.meta.base, channel: $0.channel))}
        }
        return repos
    }
    
    public func allStatuses(repo: RepoRecord, target: InstallerTarget) throws -> [String: PackageStatusResponse] {
        let repoRecordStr = String(data: try JSONEncoder().encode(repo), encoding: .utf8)!
        
        let statusesCStr = repoRecordStr.withCString { cStr in
            target.stringValue.withCString { targetCStr in
                pahkat_macos_package_store_all_statuses(handle, cStr, targetCStr, pahkat_client_err_callback)
            }
        }
        try assertNoError()
        defer { pahkat_str_free(statusesCStr) }
        
        let statusesData = String(cString: statusesCStr!).data(using: .utf8)!
        let statuses = try jsonDecoder.decode(
            [String: PackageInstallStatus].self,
            from: statusesData)
        
        return statuses.mapValues { status in
            PackageStatusResponse(status: status, target: InstallerTarget.system)
        }
    }
    
    private struct FindPackageByIdResponse: Codable {
        let packageKey: PackageKey
        let package: Package
    }
    
//    func findPackage(byId id: String) throws -> (PackageKey, Package)? {
//        let ptr = id.withCString { cStr in
//            pahkat_macos_package_store_find_package_by_id(handle, cStr, pahkat_client_err_callback)
//        }
//        try assertNoError()
//        
//        if ptr == nil {
//            return nil
//        }
//        
//        defer { pahkat_str_free(ptr) }
//        let data = String(cString: ptr!).data(using: .utf8)!
//        
//        let response = try jsonDecoder.decode(FindPackageByIdResponse.self, from: data)
//        return (response.packageKey, response.package)
//    }
    
    func findPackage(byKey key: PackageKey) throws -> Package? {
        let ptr = key.rawValue.withCString { cStr in
            pahkat_macos_package_store_find_package_by_key(handle, cStr, pahkat_client_err_callback)
        }
        try assertNoError()
        
        if ptr == nil {
            return nil
        }
        
        defer { pahkat_str_free(ptr) }
        let data = String(cString: ptr!).data(using: .utf8)!
        return try jsonDecoder.decode(Package.self, from: data)
    }
    
    public func transaction(actions: [TransactionAction<InstallerTarget>]) throws -> PackageTransaction<InstallerTarget> {
        print("Encoding: \(actions)")
        let jsonActions = try JSONEncoder().encode(actions)
        print("Encoded: \(jsonActions)")
        let ptr = String(data: jsonActions, encoding: .utf8)!.withCString { cStr in
            pahkat_macos_transaction_new(handle, cStr, pahkat_client_err_callback)
        }
        try assertNoError()
        return PackageTransaction(handle: ptr!, actions: actions, rawProcessFunc: .macos)
    }
    
    deinit {
        // TODO
    }
}

#endif
