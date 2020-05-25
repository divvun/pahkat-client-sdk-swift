//
//  Empty.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public struct Empty: Codable, Equatable, Hashable {
    public static let instance = Empty()
    private init() {}
    public init(from decoder: Decoder) throws {
        self = Empty.instance
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("system")
    }
}
