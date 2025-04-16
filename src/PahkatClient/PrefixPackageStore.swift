import Foundation

public class Pahkat {
    public static func enableLogging() {
        pahkat_enable_logging(5)
    }
}

public class PrefixPackageStore: NSObject {
    public var backgroundURLSessionCompletion: (() -> Void)? // TODO: consider making this more elegant
    private let handle: UnsafeRawPointer
    private let configHandle: UnsafeRawPointer

    public static func create(path prefixPath: String) throws -> PrefixPackageStore {
        let handle = prefixPath.withRustSlice {
            pahkat_prefix_package_store_create($0, errCallback)
        }
        try assertNoError()

        let configHandle = pahkat_prefix_package_store_config(handle!!, errCallback)
        try assertNoError()

        return PrefixPackageStore(handle: handle!!, configHandle: configHandle!)
    }

    public static func open(path prefixPath: String) throws -> PrefixPackageStore {
        let handle = prefixPath.withRustSlice {
            pahkat_prefix_package_store_open($0, errCallback)
        }
        try assertNoError()

        let configHandle = pahkat_prefix_package_store_config(handle!!, errCallback)
        try assertNoError()

        return PrefixPackageStore(handle: handle!!, configHandle: configHandle!)
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

    internal init(handle: UnsafeRawPointer, configHandle: UnsafeRawPointer) {
        self.handle = handle
        self.configHandle = configHandle
    }

    public func resolvePackage(packageKey: PackageKey) throws -> Package? {
        let cJsonPackage = packageKey.toString().withRustSlice { cPackageKey in
            pahkat_prefix_package_store_find_package_by_key(handle, cPackageKey, errCallback)
        }
        try assertNoError()
        defer { pahkat_str_free(cJsonPackage!) }
        let data = String.from(slice: cJsonPackage!).data(using: .utf8)!
        return try JSONDecoder().decode(Package.self, from: data)
    }

    private var downloadCallbacks: Mutex<[PackageKey: (Error?, String?) -> ()]> = Mutex([:])

    @discardableResult
    public func download(packageKey: PackageKey, completion: ((Error?, String?) -> ())? = nil) throws -> URLSessionDownloadTask {
        print("DOWNLOAD")
//        guard let package = try self.resolvePackage(packageKey: packageKey) else {
//            throw PahkatClientError(message: "No package found for \(packageKey.rawValue)")
//        }
//
//        guard let installer = package.tarballInstaller else {
//            throw PahkatClientError(message: "No tarball installer for \(packageKey.rawValue)")
//        }

        let urlPtr = packageKey.toString().withRustSlice { cPackageKey in
            pahkat_prefix_package_store_download_url(handle, cPackageKey, errCallback)
        }
        try assertNoError(context: "Internal error while downloading \(packageKey.toString())")
        let url = URL(string: String.from(slice: urlPtr!))!

        let task = self.urlSession.downloadTask(with: url)
        task.taskDescription = packageKey.toString()

        if #available(OSX 10.13, iOS 11.0, *) {
//            task.countOfBytesClientExpectsToReceive = Int64(installer.size)
        } else {
            // Do nothing.
        }

        if let completion = completion {
            let lock = downloadCallbacks.lock()
            lock.value[packageKey] = completion
        }

        print("RESUME \(url)")

        task.resume()
        return task
    }

    public func `import`(packageKey: PackageKey, installerPath: String) throws -> String {
        let slice = packageKey.toString().withRustSlice { cPackageKey in
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

    public func status(for packageKey: PackageKey) throws -> PackageInstallStatus {
        let status = packageKey.toString().withRustSlice { cStr in
            pahkat_prefix_package_store_status(handle, cStr, errCallback)
        }
        try assertNoError()

        return PackageInstallStatus.init(rawValue: status!) ?? PackageInstallStatus.invalidMetadata
    }

    public func transaction(actions: [TransactionAction<Empty>]) throws -> PackageTransaction<Empty> {
        print("Encoding: \(actions)")
        let jsonActions = try JSONEncoder().encode(actions)
        let s = String(data: jsonActions, encoding: .utf8)!
        print("Encoded: \(s)")
        let ptr = s.withRustSlice { cStr in
            pahkat_prefix_transaction_new(handle, cStr, errCallback)
        }
        try assertNoError()
        return PackageTransaction(handle: ptr!!, actions: actions, rawProcessFunc: .prefix)
    }

    public func set(repos: [URL: RepoRecord]) throws {
        var stringRepos = [String: RepoRecord]()
        for (k, v) in repos {
            stringRepos[k.absoluteString] = v
        }
        let jsonRepos = try JSONEncoder().encode(stringRepos)
        let repos = String(data: jsonRepos, encoding: .utf8)!
        print(repos)

        repos.withRustSlice { cStr in
            pahkat_config_repos_set(configHandle, cStr, errCallback)
        }

        try assertNoError()
    }
}

#if os(iOS)
extension PrefixPackageStore: URLSessionDelegate {
    @available(iOS 9.0, *)
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        backgroundURLSessionCompletion?()
    }
}
#endif


extension PrefixPackageStore: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("\(String(describing: downloadTask.packageKey)): \(fileOffset)/\(expectedTotalBytes)")
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let packageKey = task.packageKey else {
            print(error as Any)
            print("Unknown download task, ignoring.")
            print(task)
            return
        }


        if let error = error {
            print("An error occurred downloading \(String(describing: task.packageKey)): \(error)")
            let lock = self.downloadCallbacks.lock()
            lock.value[packageKey]?(error, nil)
            lock.value.removeValue(forKey: packageKey)
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let packageKey = downloadTask.packageKey else {
            print("Unknown download task, ignoring.")
            print(downloadTask)
            return
        }

        defer {
            let lock = self.downloadCallbacks.lock()
            lock.value.removeValue(forKey: packageKey)
        }

        print("Path: \(location.path)")

        do {
            let lock = self.downloadCallbacks.lock()
            let path = try self.import(packageKey: packageKey, installerPath: location.path)
            print("Path imported: \(path)")
            lock.value[packageKey]?(nil, path)
        } catch {
            print(error)
            let lock = self.downloadCallbacks.lock()
            lock.value[packageKey]?(error, nil)
        }
    }
}

fileprivate extension URLSessionTask {
    var packageKey: PackageKey? {
        guard let s = self.taskDescription else { return nil }
        guard let url = URL(string: s) else { return nil }
        return try? PackageKey.from(url: url)
    }
}
