import Foundation

struct PackageKey {
    
}

class PrefixPackageStore: NSObject {
    private let handle: UnsafeRawPointer
    
    private lazy var urlSession: URLSession = {
        let bundle = Bundle.main.bundleIdentifier ?? "app"
        let config = URLSessionConfiguration.background(withIdentifier: "\(bundle).PahkatClient")
        config.isDiscretionary = true
#if TARGET_OS_IPHONE
        if #available(iOS 9.0, *) {
            config.sessionSendsLaunchEvents = true
        }
#endif
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    internal init(handle: UnsafeRawPointer) {
        self.handle = handle
    }
    
    static func open(path: String) throws -> PrefixPackageStore {
        let ptr = path.withCString {
            return pahkat_prefix_package_store_open($0, pahkat_client_err_callback)
        }
        
        
        return PrefixPackageStore(handle: ptr!)
    }
    
    func download(packageKey: PackageKey) {
        // Resolve package
//        let task = self.urlSession.downloadTask(with: <#T##URLRequest#>)
//        task.countOfBytesClientExpectsToReceive = package.size
//        task.resume()
    }
}

#if TARGET_OS_IPHONE
extension PrefixPackageStore: URLSessionDelegate {
    @available(iOS 9.0, *)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // TODO
    }
}
#endif

extension PrefixPackageStore: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // TODO
    }
}
