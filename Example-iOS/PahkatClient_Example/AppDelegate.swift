//
//  AppDelegate.swift
//  PahkatClient_Example
//
//  Created by Brendan Molloy on 2019-11-15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import PahkatClient

class D: PackageTransactionDelegate {
    func isTransactionCancelled(_ id: UInt32) -> Bool {
        return false
    }

    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey) {
        print(#function, "\(id)")
    }

    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey) {
        print(#function, "\(id)")
    }

    func transactionDidComplete(_ id: UInt32) {
        print(#function, "\(id)")
    }

    func transactionDidCancel(_ id: UInt32) {
        print(#function, "\(id)")
    }

    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
        print(#function, "\(id) \(String(describing: error))")
    }

    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32) {
        print(#function, "\(id)")
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var downloading: URLSessionDownloadTask? = nil


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        pahkat_enable_logging()
        
        let base = NSHomeDirectory()
        print(base)
        
        let store: PrefixPackageStore
        do {
           store = try PrefixPackageStore.create(path: "\(base)/pahkat-client-prefix")
        } catch {
           do {
               store = try PrefixPackageStore.open(path: "\(base)/pahkat-client-prefix")
           } catch {
               print(error)
               return true
           }
        }

        do {
//           let config = try store.config()
           let url = URL(string: "https://x.brendan.so/divvun-pahkat-repo/")!
//           try config.set(repos: [RepoRecord(url: url, channel: .stable)])
           try store.forceRefreshRepos()
        } catch {
           print(error)
           return true
        }

//        guard let indexes = try? store.repoIndexes(),
//            let index = indexes.first,
//            let pkg = index.packages.values.first else {
//                print("no package found!")
//                return true
//        }
//        let pkgKey = index.absoluteKey(for: pkg)

//        print("Package key: \(pkgKey)")
////        let status = index.status(for: pkgKey)
//        print(try! store.allStatuses(repo: RepoRecord(url: index.meta.base, channel: .stable)))
        let pkgKey = PackageKey(from: URL(string: "https://x.brendan.so/divvun-pahkat-repo/packages/speller-sme?platform=ios")!)

        do {
           downloading = try store.download(packageKey: pkgKey) { (error, path) in
               if let error = error {
                   print(error)
                   return
               }
               
               if let path = path {
                   print(path)
               }
               
               let action = TransactionAction.install(pkgKey)
               
               do {
                   let tx = try store.transaction(actions: [action])
                   let d = D()
                   tx.process(delegate: d)
               } catch {
                   print(error)
               }
               print("Done!")
           }
        } catch {
            print("Some error")
            print(error)
        }
        print("Oh lawd they doing")
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

