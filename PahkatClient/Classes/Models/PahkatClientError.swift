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

private var pahkat_client_err: PahkatClientError? = nil

internal let pahkat_client_err_callback: @convention(c) (UnsafePointer<Int8>) -> Void = { cStr in
    let error = String(cString: cStr)
    pahkat_client_err = PahkatClientError(message: error)
}

internal func assertNoError() throws {
    if let err = pahkat_client_err {
        pahkat_client_err = nil
        throw err
    }
}
