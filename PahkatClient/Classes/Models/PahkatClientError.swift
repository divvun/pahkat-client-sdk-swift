//
//  PahkatClientError.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public struct PahkatClientError: Error {
    public let context: String?
    public let message: String
    public let stack: [String]

    init(message: String, context: String?) {
        self.context = context
        self.message = message
        stack = Thread.callStackSymbols
    }
}

extension PahkatClientError: CustomDebugStringConvertible {
    public var debugDescription: String {
        let msg = "PahkatClientError(\(context ?? "<none>")): \(message)\n  Stacktrace:\n"
        return msg + stack.joined(separator: "\n")
    }
}

extension PahkatClientError: CustomStringConvertible {
    public var description: String {
        if let context = context {
            return context
        }
        return message
    }
}

private var err: String? = nil

internal func assertNoError(context: String? = nil) throws {
    if let err1 = err {
        err = nil
        throw PahkatClientError(message: err1, context: context)
    }
}

let errCallback: @convention(c) (UnsafeMutableRawPointer?, rust_usize_t) -> Void = {
    (ptr, len) in

    if let ptr = ptr {
        err = String(bytes: rust_slice_t(data: ptr, len: len), encoding: .utf8) ?? "<unknown>"
    }
}
