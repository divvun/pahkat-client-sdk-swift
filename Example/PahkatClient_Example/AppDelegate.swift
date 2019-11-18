//
//  AppDelegate.swift
//  PahkatClient_Example
//
//  Created by Brendan Molloy on 2019-11-14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Cocoa
import PahkatClient

class D: PackageTransactionDelegate {
    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey) {
        
    }
    
    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey) {
        
    }
    
    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
        
    }
    
    func transactionDidComplete(_ id: UInt32) {
        
    }
    
    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32) {
        
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    private var downloading: URLSessionDownloadTask? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        pahkat_enable_logging()
        
        let store: PrefixPackageStore
        do {
            store = try PrefixPackageStore.create(path: "/tmp/pahkat-client-prefix")
        } catch {
            do {
                store = try PrefixPackageStore.open(path: "/tmp/pahkat-client-prefix")
            } catch {
                print(error)
                return
            }
        }
        
        do {
            let config = try store.config()
            let url = URL(string: "http://localhost:5000/")!
            try config.set(repos: [RepoRecord(url: url, channel: .stable)])
            try store.forceRefreshRepos()
        } catch {
            print(error)
            return
        }
        
        let indexes = try! store.repoIndexes()
        let index = indexes.first!
        print(try! store.allStatuses(repo: RepoRecord(url: index.meta.base, channel: .stable)))
        let pkg = index.packages.values.first!
        let pkgKey = index.absoluteKey(for: pkg)
        
        print("Package key: \(pkgKey)")
        
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
            print(error)
        }
        print("Oh lawd they doing")
        
//        let tx =
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

