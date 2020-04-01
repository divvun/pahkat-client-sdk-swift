//
//  TransactionHandler.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

internal var transactionProcessCallbacks = [UInt32: PackageTransactionDelegate]()


internal let transactionProcessHandler: @convention(c) (UInt32, rust_slice_t, UInt32) -> rust_bool_t = { tag, cPackageKey, cEvent in
    guard let delegate = transactionProcessCallbacks[tag] else {
        // TODO: log
        return false
    }
    
    if delegate.isTransactionCancelled(tag) {
        delegate.transactionDidCancel(tag)
        transactionProcessCallbacks.removeValue(forKey: tag)
        return false
    }
    
    let packageKey = PackageKey(from: URL(string: String.from(slice: cPackageKey))!)
    
    guard let event = PackageTransactionEvent(rawValue: cEvent) else {
        delegate.transactionDidUnknownEvent(tag, packageKey: packageKey, event: cEvent)
        return delegate.isTransactionCancelled(tag).into()
    }
    
    switch event {
    case .installing:
        delegate.transactionWillInstall(tag, packageKey: packageKey)
    case .uninstalling:
        delegate.transactionWillUninstall(tag, packageKey: packageKey)
    case .error:
        delegate.transactionDidError(tag, packageKey: packageKey, error: nil)
        transactionProcessCallbacks.removeValue(forKey: tag)
    case .completed:
        delegate.transactionDidComplete(tag)
        transactionProcessCallbacks.removeValue(forKey: tag)
    case .notStarted:
        break
    }
    
    return !delegate.isTransactionCancelled(tag).into()
}
