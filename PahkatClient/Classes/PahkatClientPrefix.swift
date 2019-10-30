//import Foundation
//
//struct PackageKey {
//    
//}
//
//class PrefixPackageStore: NSObject {
//    private let handle: UnsafeRawPointer
//    
//    private lazy var urlSession: URLSession = {
//        let config = URLSessionConfiguration.background(withIdentifier: "MySession")
//        config.isDiscretionary = true
//        if #available(iOS 9.0, *) {
//            config.sessionSendsLaunchEvents = true
//        }
//        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
//    }()
//    
//    internal init(handle: UnsafeRawPointer) {
//        self.handle = handle
//    }
//    
//    static func open(path: String) throws -> PrefixPackageStore {
//        let ptr = path.withCString {
//            return pahkat_prefix_package_store_open($0, pahkat_client_err_callback)
//        }
//        
//        
//        return PrefixPackageStore(handle: ptr!)
//    }
//    
//    func download(packageKey: PackageKey) {
//        // Resolve package
//        let task = self.urlSession.downloadTask(with: <#T##URLRequest#>)
//        task.countOfBytesClientExpectsToReceive = package.size
//        task.resume()
//    }
//}
//
//extension PrefixPackageStore: URLSessionDelegate {
//    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        // TODO
//    }
//}
//
//extension PrefixPackageStore: URLSessionDownloadDelegate {
//    // TODO
//}
