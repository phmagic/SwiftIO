//
//  BinaryOutputStreams.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

public protocol BinaryOutputStream {
   func write(buffer:UnsafeBufferPointer <Void>) throws
}

// MARK: -

public protocol BinaryOutputStreamable {
    func writeTo <Target:BinaryOutputStream> (stream:Target) throws
}

public extension BinaryOutputStream {
    func write <Target:BinaryOutputStreamable> (value:Target) throws {
        try value.writeTo(self)
    }
}

// MARK: -

extension Int32: BinaryOutputStreamable {
    public func writeTo <Target:BinaryOutputStream> (stream:Target) throws {
        var value = self
        let buffer = withUnsafePointer(&value) {
            (pointer:UnsafePointer <Int32>) -> UnsafeBufferPointer <Void> in
            return UnsafeBufferPointer(start: pointer, count: sizeof(Int32))
        }
        try stream.write(buffer)
    }
}

extension NSData: BinaryOutputStreamable {
    public func writeTo <Target:BinaryOutputStream> (stream:Target) throws {
        let buffer = UnsafeBufferPointer <Void> (start: bytes, count: length)
        try stream.write(buffer)
    }
}

// MARK: -

public extension BinaryOutputStream {

    func write(string:String, appendNewline: Bool = false) throws {
        let string = appendNewline == true ? string : string + "\n"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let buffer = UnsafeBufferPointer <Void> (start:data.bytes, count:data.length)
        try write(buffer)
    }
}

// MARK: -

