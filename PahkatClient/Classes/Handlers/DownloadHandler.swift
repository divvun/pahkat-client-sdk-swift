//
//  DownloadHandler.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

internal var downloadProcessCallbacks = [PackageKey: PackageDownloadDelegate]()

internal let downloadProcessHandler: @convention(c) (UnsafePointer<CChar>, UInt64, UInt64) -> UInt8 = { cPackageKey, current, maximum in
    
    let packageKey = PackageKey(from: URL(string: String(cString: cPackageKey))!)
    
    guard let delegate = downloadProcessCallbacks[packageKey] else {
        // TODO: log
        return 0
    }

    delegate.downloadDidProgress(packageKey, current: current, maximum: maximum)
    return delegate.isDownloadCancelled ? 0 : 1
}
