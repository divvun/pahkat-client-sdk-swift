import Foundation

struct PahkatClientError: Error {
    let message: String
}

private func assertNoError() throws {
    if pahkat_client_err != nil {
        let error = String(cString: pahkat_client_err!)
        pahkat_client_err_free()
        throw PahkatClientError(message: error)
    }
}

//@available(macOS 10.10, *)
class MacOSPackageStore {
    static func `default`() -> MacOSPackageStore {
        let handle = pahkat_macos_package_store_default()
        return MacOSPackageStore(handle: handle)
    }
    
    static func create(path: String) throws -> MacOSPackageStore {
        fatalError()
    }
    
    static func load(path: String) throws -> MacOSPackageStore {
        fatalError()
    }
    
    func clearCache() throws {
    }
    
    private let handle: UnsafeRawPointer
    
    private init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    deinit {
        // TODO
    }
}

