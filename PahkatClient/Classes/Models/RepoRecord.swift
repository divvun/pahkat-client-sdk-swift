//
//  RepoRecord.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public struct RepoRecord: Codable, Equatable, Hashable {
    public let channel: String?

    public init(channel: String?) {
        self.channel = channel
    }
}
