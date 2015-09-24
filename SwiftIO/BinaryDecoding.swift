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

public protocol BinaryDecodable {
    static func decode(buffer: UnsafeBufferPointer <Void>) throws -> Self
}

extension IntegerType {
    public static func decode(buffer: UnsafeBufferPointer <Void>) throws -> Self {
        typealias Type = Self
        guard buffer.count >= sizeof(Type) else {
            throw Error.generic("Not enough bytes for \(Type.self) decoding.")
        }
        let pointer = UnsafePointer <Type> (buffer.baseAddress)
        return pointer.memory
    }
}

extension UnsignedIntegerType {
    public static func decode(buffer: UnsafeBufferPointer <Void>) throws -> Self {
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
