//
//  PackageTransactionEvent.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public enum PackageTransactionEvent: UInt32, Codable {
    case notStarted = 0
    case uninstalling = 1
    case installing = 2
    case completed = 3
    case error = 4
}
