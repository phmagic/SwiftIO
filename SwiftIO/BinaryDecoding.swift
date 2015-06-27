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
    static func decode(buffer:UnsafeBufferPointer <Void>, endianness:Endianess) throws -> Self
}

extension Int32: BinaryDecodable {
    public static func decode(buffer:UnsafeBufferPointer <Void>, endianness:Endianess) throws -> Int32 {
        guard buffer.count >= sizeof(Int32) else {
            throw Error.generic("Not enough bytes for Int32")
        }
        let pointer = UnsafePointer <Int32> (buffer.baseAddress)
        if endianness == .big {
            return Int32(bigEndian:pointer.memory)
        }
        else {
            return Int32(littleEndian:pointer.memory)
        }
    }
}
