//
//  TypedData.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

// MARK: -

public typealias BinaryInputOutputStreamable = protocol <BinaryInputStreamable, BinaryOutputStreamable>

// TODO: Make T not require BinaryOutputStreamable and move it onto the typedData extension!
public struct TypedData <T:BinaryInputOutputStreamable> {
    let type:T
    let buffer:Buffer <Void>
}

extension TypedData: BinaryOutputStreamable {
    public func writeTo <Target:BinaryOutputStream> (stream:Target) throws {
        try stream.write(Int32(buffer.count))
        try stream.write(type)
        try stream.write(buffer.bufferPointer)
    }
}


extension TypedData: BinaryInputStreamable {
    public static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> TypedData {
        let length:Int32 = try stream.read()
        let type:T = try stream.read()
        let buffer:Buffer <Void> = try stream.read(Int(length))
        return TypedData(type:type, buffer:buffer)
    }
}
