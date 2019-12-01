//
//  RepoRecord.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public struct RepoRecord: Codable, Equatable, Hashable {
    public let url: URL
    public let channel: Repository.Channels
    
    public init(url: URL, channel: Repository.Channels) {
        self.url = url
        self.channel = channel
    }
}
