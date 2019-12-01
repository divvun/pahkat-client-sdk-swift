//
//  PackageTransactionDelegate.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public protocol PackageTransactionDelegate: class {
    func isTransactionCancelled(_ id: UInt32) -> Bool
    
    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey)
    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey)
    func transactionDidComplete(_ id: UInt32)
    func transactionDidCancel(_ id: UInt32)
    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?)
    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32)
}
