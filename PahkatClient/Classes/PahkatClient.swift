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

public struct RepoConfig: Codable, Equatable {
    public let url: URL
    public let channel: Repository.Channels
    
    public static func ==(lhs: RepoConfig, rhs: RepoConfig) -> Bool {
        return lhs.url == rhs.url && lhs.channel == rhs.channel
    }
    
    public init(url: URL, channel: Repository.Channels) {
        self.url = url
        self.channel = channel
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
    
    public func repos() throws -> [RepoConfig] {
        let cStr = pahkat_store_config_repos(handle, pahkat_client_err_callback)
        try assertNoError()
        
        defer { pahkat_str_free(cStr) }
        let data = String(cString: cStr!).data(using: .utf8)!
        
//        log.debug("Decode repos")
        return try! JSONDecoder().decode([RepoConfig].self, from: data)
    }
    
    public func set(repos: [RepoConfig]) throws {
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
