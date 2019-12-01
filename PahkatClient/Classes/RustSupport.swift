//
//  RustSupport.swift
//  PahkatClient
//
//  Created by Brendan Molloy on 2019-11-26.
//

import Foundation

public struct SliceIterator: IteratorProtocol {
    private let slice: rust_slice_t
    private var current: Int = 0
    
    public typealias Element = UInt8
    
    public mutating func next() -> UInt8? {
        if current >= self.slice.len {
            return nil
        }
        
        let v = self.slice.data!
            .assumingMemoryBound(to: UInt8.self)
            .advanced(by: current)
            .pointee
        
        self.current += 1
        
        return v
    }
    
    init(_ slice: rust_slice_t) {
        self.slice = slice
    }
}

extension rust_slice_t: Sequence {
    public typealias Element = UInt8
    public typealias Iterator = SliceIterator
    
    public var underestimatedCount: Int {
        return Int(self.len)
    }
    
    public func makeIterator() -> SliceIterator {
        return SliceIterator(self)
    }
}

extension rust_slice_t: Collection {
    public typealias Index = UInt
    
    public var startIndex: UInt { return 0 }
    public var endIndex: UInt { return self.len }
    
    public func index(after i: UInt) -> UInt {
        return i + 1
    }
    
    public subscript(position: UInt) -> UInt8 {
        return self.data!
            .assumingMemoryBound(to: UInt8.self)
            .advanced(by: Int(position))
            .pointee
    }
}
