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

extension String {
    @inlinable
    func ensureContiguous() -> String {
        if self.isContiguousUTF8 {
            return self
        } else {
            var copied = self
            copied.makeContiguousUTF8()
            return copied
        }
    }
    
    @inlinable
    func withRustSlice<T>(callback: (rust_slice_t) -> T) -> T? {
        let value = self.ensureContiguous()
        
        return value.utf8.withContiguousStorageIfAvailable { pointer in
            let raw = UnsafeMutableRawPointer(mutating: pointer.baseAddress!)
            let slice = rust_slice_t(data: raw, len: rust_usize_t(pointer.count))
            return callback(slice)
        }
    }
    
    @inlinable
    static func from(slice: rust_slice_t) -> String {
        return String(bytes: slice, encoding: .utf8) ?? ""
    }
}

extension rust_bool_t: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    
    @inlinable
    public init(booleanLiteral value: Bool) {
        self.init()
        self.internal_value = value ? 1 : 0
    }
    
    @inlinable
    public var value: Bool {
        self.internal_value != 0
    }
}

extension Bool {
    @inlinable
    func into() -> rust_bool_t {
        self ? true : false
    }
}

extension rust_bool_t {
    @inlinable
    static prefix func !(this: rust_bool_t) -> rust_bool_t {
        return this.internal_value == 0 ? true : false
    }
}

class Mutex<T> {
    fileprivate var semaphore = DispatchSemaphore(value: 1)
    fileprivate var item: T

    public init(_ item: T) {
        self.item = item
    }

    public func lock() -> MutexGuard<T> {
        self.semaphore.wait()
        return MutexGuard(self)
    }
}

class MutexGuard<T> {
    private unowned let mutex: Mutex<T>

    var value: T {
        get {
            mutex.item
        }
        set {
            mutex.item = newValue
        }
    }

    deinit {
        mutex.semaphore.signal()
    }

    fileprivate init(_ mutex: Mutex<T>) {
        self.mutex = mutex
    }
}
