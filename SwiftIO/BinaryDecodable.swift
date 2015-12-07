//
//  BinaryDecoding.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//
//  Copyright (c) 2014, Jonathan Wight
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import SwiftUtilities

public protocol BinaryDecodable: EndianConvertable {
    static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> Self
}

// MARK: -

private func decode <T> (buffer: UnsafeBufferPointer <Void>) throws -> T {
    guard buffer.count >= sizeof(T) else {
        throw Error.Generic("Not enough bytes for \(T.self) decoding.")
    }
    let pointer = UnsafePointer <T> (buffer.baseAddress)
    let value = pointer.memory
    return value
}

// MARK: -

extension Int: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> Int {
        let value: Int = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension Int8: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> Int8 {
        let value: Int8 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension Int16: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> Int16 {
        let value: Int16 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension Int32: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> Int32 {
        let value: Int32 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension Int64: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> Int64 {
        let value: Int64 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

// MARK: -

extension UInt: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> UInt {
        let value: UInt = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension UInt8: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> UInt8 {
        let value: UInt8 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension UInt16: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> UInt16 {
        let value: UInt16 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension UInt32: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> UInt32 {
        let value: UInt32 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

extension UInt64: BinaryDecodable {
    public static func decode(buffer: UnsafeBufferPointer <Void>, endianess: Endianess) throws -> UInt64 {
        let value: UInt64 = try SwiftIO.decode(buffer)
        return value.fromEndianess(endianess)
    }
}

