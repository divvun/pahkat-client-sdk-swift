//
//  PackageStore.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

protocol PackageStore: class {
    associatedtype Target: Codable
    
    func config() throws -> StoreConfig
    func repoIndexes(withStatuses: Bool) throws -> [RepositoryIndex]
    func allStatuses(repo: RepoRecord, target: Target) throws -> [String: PackageStatusResponse]
    func download(packageKey: PackageKey, delegate: PackageDownloadDelegate)
    func `import`(packageKey: PackageKey, installerPath: String) throws -> String
//    func install()
//    func uninstall()
//    func status()
//    func findPackage(byId: String) throws -> (PackageKey, Package)?
    func findPackage(byKey: PackageKey) throws -> Package?
    func refreshRepos() throws
    func clearCache() throws
    func forceRefreshRepos() throws
    func set(repos: [URL: RepoRecord])
//    func addRepo()
//    func removeRepo()
//    func updateRepo()
    
    func transaction(actions: [TransactionAction<Target>]) throws -> PackageTransaction<Target>
}
