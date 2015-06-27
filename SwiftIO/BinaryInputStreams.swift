//
//  BinaryStreams.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

public protocol BinaryInputStream {
    func read(length:Int) throws -> Buffer <Void>
}

// MARK: -

public extension BinaryInputStream {

    func read <T:BinaryDecodable> () throws -> T {
        return try read(sizeof(T))
    }

    func read <T:BinaryDecodable> (size:Int) throws -> T {
        let buffer = try read(size)
        let value = try T.decode(buffer.bufferPointer, endianness: Endianess.network)
        return value
    }
}

// MARK: -

public protocol BinaryInputStreamable {
     static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Self
}

public extension BinaryInputStream {
    func read <T:BinaryInputStreamable> () throws -> T {
        return try T.readFrom(self)
    }
}

// MARK: -

//extension Int32: BinaryInputStreamable {
//     public static func readFrom <Stream:BinaryInputStream> (stream:Stream, handler:(ReadResult <Int32>) -> Void) throws {
//
////        try! stream.read() {
////            (readResult:ReadResult <Int32>) in
////
////            handler(readResult)
////
////        }
//     }
//}
