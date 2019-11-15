import Foundation

//private func assertNoError() throws {
//    if pahkat_client_err != nil {
//        let error = String(cString: pahkat_client_err!)
//        pahkat_client_err_free()
//        throw PahkatClientError(message: error)
//    }
//}

@available(macOS 10.10, *)
class MacOSPackageStore {
    static func `default`() -> MacOSPackageStore {
        let handle = pahkat_macos_package_store_default()
        return MacOSPackageStore(handle: handle)
    }
    
    static func create(path: String) throws -> MacOSPackageStore {
        let handle = path.withCString {
            pahkat_macos_package_store_new($0, pahkat_client_err_callback)
        }
        try assertNoError()
        return MacOSPackageStore(handle: handle!)
    }
    
    static func load(path: String) throws -> MacOSPackageStore {
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
    
    func download() {
        
    }
    
    func resolvePackage() {
        
    }
    
    func clearCache() throws {
        pahkat_macos_package_store_clear_cache(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    func refreshRepos() throws {
        pahkat_macos_package_store_refresh_repos(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    func forceRefreshRepos() throws {
        pahkat_macos_package_store_force_refresh_repos(handle, pahkat_client_err_callback)
        try assertNoError()
    }
    
    func repoIndexes() throws -> [RepositoryIndex] {
        let repoIndexsCStr = pahkat_macos_package_store_repo_indexes(handle, pahkat_client_err_callback)
        try assertNoError()
        defer { pahkat_str_free(repoIndexsCStr) }
        
        let jsonDecoder = JSONDecoder()
                
        let reposStr = String(cString: repoIndexsCStr!)
        let reposJson = reposStr.data(using: .utf8)!
        
        let repos = try jsonDecoder.decode([RepositoryIndex].self, from: reposJson)
        return repos
    }
    
    deinit {
        // TODO
    }
}
