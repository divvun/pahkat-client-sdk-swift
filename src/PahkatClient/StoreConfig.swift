//
//  StoreConfig.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public class StoreConfig {
    private let handle: UnsafeRawPointer
    
    init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
//    public func configPath() throws -> String {
//        let slice = pahkat_store_config_config_path(handle, errCallback)
//        // TODO: free
//        try assertNoError()
//        return String(bytes: slice, encoding: .utf8)!
//    }
    
//    public func set(uiSetting key: String, value: String?) throws {
//        key.withCString { key in
//            if let value = value {
//                value.withCString { value in
//                    pahkat_store_config_set_ui_value(handle, key, value, errCallback)
//                }
//            } else {
//                pahkat_store_config_set_ui_value(handle, key, nil, errCallback)
//            }
//        }
//
//        try assertNoError()
//    }
//
//    public func get(uiSetting key: String) throws -> String? {
//        let cValue = key.withCString { key in
//            pahkat_store_config_ui_value(handle, key, errCallback)
//        }
//
//        try assertNoError()
//
//        if let cValue = cValue {
//            defer { pahkat_str_free(cValue) }
//            return String(cString: cValue)
//        } else {
//            return nil
//        }
//    }
    
//    public func repos() throws -> [RepoRecord] {
//        let cStr = pahkat_store_config_repos(handle, errCallback)
//        try assertNoError()
//
//        defer { pahkat_str_free(cStr) }
//        let data = String(cString: cStr!).data(using: .utf8)!
//
////        log.debug("Decode repos")
//        return try! JSONDecoder().decode([RepoRecord].self, from: data)
//    }
//
//    public func set(repos: [RepoRecord]) throws {
//        let json = try! JSONEncoder().encode(repos)
//        String(data: json, encoding: .utf8)!.withCString { cStr in
//            pahkat_store_config_set_repos(handle, cStr, errCallback)
//        }
//        try assertNoError()
//    }
//
//    public func setCacheBase(url: URL) throws {
//        url.absoluteString.withCString { cStr in
//            pahkat_store_config_set_cache_base_url(handle, cStr, errCallback)
//        }
//        try assertNoError()
//    }
//
//    public func setCacheBase(path: String) throws {
//        let url = URL(fileURLWithPath: path)
//        return try setCacheBase(url: url)
//    }
//
//    public func cacheBaseURL() throws -> URL {
//        let cStr = pahkat_store_config_cache_base_url(handle, errCallback)
//        try assertNoError()
//        defer { pahkat_str_free(cStr) }
//
//        // This cannot fail as the Rust contract guarantees a real pointer if no error
//        let urlString = String(cString: cStr!)
//
//        // This cannot fail because the Rust contract guarantees a URL
//        return URL(string: urlString)!
//    }
}
