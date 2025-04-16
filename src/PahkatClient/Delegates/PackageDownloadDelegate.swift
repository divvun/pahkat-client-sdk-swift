//
//  PackageDownloadDelegate.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public protocol PackageDownloadDelegate: AnyObject {
    var isDownloadCancelled: Bool { get }
    
    func downloadDidProgress(_ packageKey: PackageKey, current: UInt64, maximum: UInt64)
    func downloadDidComplete(_ packageKey: PackageKey, path: String)
    func downloadDidCancel(_ packageKey: PackageKey)
    func downloadDidError(_ packageKey: PackageKey, error: Error)
}
