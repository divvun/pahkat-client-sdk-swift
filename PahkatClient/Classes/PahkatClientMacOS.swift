import Foundation

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
    
    func repoIndexes() throws -> String {
        let repoIndexsCStr = pahkat_macos_package_store_repo_indexes(handle, pahkat_client_err_callback)
        try assertNoError()
        return "TODO"
    }
    
    deinit {
        // TODO
    }
}

struct RepoConfig: Codable, Equatable {
    let url: URL
    let channel: Repository.Channels
    
    static func ==(lhs: RepoConfig, rhs: RepoConfig) -> Bool {
        return lhs.url == rhs.url && lhs.channel == rhs.channel
    }
    
    init(url: URL, channel: Repository.Channels) {
        self.url = url
        self.channel = channel
    }
}

class PahkatConfig {
    private let handle: UnsafeRawPointer
    
    init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    func set(uiSetting key: String, value: String?) throws {
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
    
    func get(uiSetting key: String) throws -> String? {
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
    
    func repos() throws -> [RepoConfig] {
        let cStr = pahkat_store_config_repos(handle, pahkat_client_err_callback)
        try assertNoError()
        
        defer { pahkat_str_free(cStr) }
        let data = String(cString: cStr!).data(using: .utf8)!
        
//        log.debug("Decode repos")
        return try! JSONDecoder().decode([RepoConfig].self, from: data)
    }
    
    func set(repos: [RepoConfig]) throws {
        let json = try! JSONEncoder().encode(repos)
        String(data: json, encoding: .utf8)!.withCString { cStr in
            pahkat_store_config_set_repos(handle, cStr, pahkat_client_err_callback)
        }
        try assertNoError()
    }
    
//    func set(cachePath: String) throws {
//        let cStr = cachePath.cString(using: .utf8)!
//        pahkat_store_config_set_cache_base_path(handle, cStr, pahkat_client_err_callback)
//        try assertNoError()
//    }
//    
//    func cachePath() throws -> String {
//        let cStr = pahkat_store_config_cache_base_path(handle, pahkat_client_err_callback)
//        try assertNoError()
//        defer { pahkat_str_free(cStr) }
//        let path = String(cString: cStr!)
//        return path
//    }
}
