//
//  BinaryDecoding.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

public protocol BinaryDecodable {
    static func decode(buffer:UnsafeBufferPointer <Void>) throws -> Self
}

extension IntegerType {
    public static func decode(buffer:UnsafeBufferPointer <Void>) throws -> Self {
        typealias Type = Self
        guard buffer.count >= sizeof(Type) else {
            throw Error.generic("Not enough bytes for \(Type.self) decoding.")
        }
        let pointer = UnsafePointer <Type> (buffer.baseAddress)
        return pointer.memory
    }
}

extension UnsignedIntegerType {
    public static func decode(buffer:UnsafeBufferPointer <Void>) throws -> Self {
        typealias Type = Self
        guard buffer.count >= sizeof(Type) else {
            throw Error.generic("Not enough bytes for \(Type.self) decoding.")
        }
        let pointer = UnsafePointer <Type> (buffer.baseAddress)
        return pointer.memory
    }
}

extension Int: BinaryDecodable {
}

extension Int8: BinaryDecodable {
}

extension Int16: BinaryDecodable {
}

extension Int32: BinaryDecodable {
}

extension Int64: BinaryDecodable {
}

extension UInt: BinaryDecodable {
}

extension UInt8: BinaryDecodable {
}

extension UInt16: BinaryDecodable {
}

extension UInt32: BinaryDecodable {
}

extension UInt64: BinaryDecodable {
}
