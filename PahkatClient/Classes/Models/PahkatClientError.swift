//
//  PahkatClientError.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public struct PahkatClientError: Error {
    public let message: String
    public let stack: [String]
    
    init(message: String) {
        self.message = message
        stack = Thread.callStackSymbols
    }
}

extension PahkatClientError: CustomDebugStringConvertible {
    public var debugDescription: String {
        let msg = "PahkatClientError: \(message)\n  Stacktrace:\n"
        return msg + stack.joined(separator: "\n")
    }
}

private var err: PahkatClientError? = nil

internal func assertNoError() throws {
    if let err1 = err {
        err = nil
        throw err1
    }
}

let errCallback: @convention(c) (UnsafeMutableRawPointer?, rust_usize_t) -> Void = {
    (ptr, len) in
    
    if let ptr = ptr {
        err = PahkatClientError(message: String(bytes: rust_slice_t(data: ptr, len: len), encoding: .utf8) ?? "<unknown>")
    }
}
