//
//  PackageTransaction.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

private var nextPackageTransactionId: UInt32 = 1

public class PackageTransaction<T: Codable> {
    private let handle: UnsafeRawPointer
    public let actions: [TransactionAction<T>]
    private let rawProcessFunc: RawProcessFunc
    
    init(handle: UnsafeRawPointer, actions: [TransactionAction<T>], rawProcessFunc: RawProcessFunc) {
        self.handle = handle
        self.actions = actions
        self.rawProcessFunc = rawProcessFunc
    }

    public func process(delegate: PackageTransactionDelegate) {
        defer { nextPackageTransactionId += 1 }
        
        let id = nextPackageTransactionId
        transactionProcessCallbacks[id] = delegate
        defer {
            transactionProcessCallbacks.removeValue(forKey: id)
        }
        
        self.rawProcessFunc.invoke(handle: handle, id: id)
        
        do {
            try assertNoError()
        } catch {
            delegate.transactionDidError(id, packageKey: nil, error: error)
        }
        
        delegate.transactionDidComplete(id)
    }
}

enum RawProcessFunc {
    #if os(macOS)
    case macos
    #endif
    case prefix
    
    func invoke(handle: UnsafeRawPointer, id: UInt32) {
        switch self {
        #if os(macOS)
        case .macos:
            pahkat_macos_transaction_process(handle, id, transactionProcessHandler, pahkat_client_err_callback)
        #endif
        case .prefix:
            pahkat_prefix_transaction_process(handle, id, transactionProcessHandler, pahkat_client_err_callback)
        }
    }
}
