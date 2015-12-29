//
//  IntegerType+BinaryOutputStreamable.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/5/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

private func write <Target: BinaryOutputStream, T: EndianConvertable> (stream: Target, value: T) throws {
    var value = value.toEndianess(stream.endianess)
    let buffer = withUnsafePointer(&value) {
        (pointer: UnsafePointer <T>) -> UnsafeBufferPointer <Void> in
        return UnsafeBufferPointer(start: pointer, count: sizeof(T))
    }
    try stream.write(buffer)
}

// MARK: -

extension Int: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension Int8: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension Int16: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension Int32: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension Int64: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

// MARK: -

extension UInt: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension UInt8: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension UInt16: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension UInt32: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

extension UInt64: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try write(stream, value: self)
    }
}

// MARK: -

extension Float: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        let bitValue = unsafeBitCast(self, UInt32.self)
        try write(stream, value: bitValue)
    }
}

extension Double: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        let bitValue = unsafeBitCast(self, UInt64.self)
        try write(stream, value: bitValue)
    }
}
