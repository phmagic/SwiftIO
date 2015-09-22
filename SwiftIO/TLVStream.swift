//
//  TVLStream.swift
//  SwiftMavlink
//
//  Created by Jonathan Wight on 8/7/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

public class TLVOutputStream {

    public typealias TypeType = UInt16
    public typealias LengthType = UInt16
    public typealias TypedData = (type:TypeType, data:UnsafeBufferPointer<Void>)

    public var outputStream: BinaryOutputStream

    public init(outputStream: BinaryOutputStream) {
        self.outputStream = outputStream
    }

    public func write(data:TypedData) throws {
        let length = LengthType(data.data.length)

        guard length <= LengthType.max else {
            throw Error.generic("Buffer too big")
        }

        try outputStream.write(data.type.networkEndian)
        try outputStream.write(length.networkEndian)
        try outputStream.write(data.data)
    }
}

public class TLVInputStream {

    public typealias TypeType = UInt16
    public typealias LengthType = UInt16
    public typealias TypedData = (type:TypeType, data:DispatchData <Void>)

    public var stream: BinaryInputStream

    init(stream: BinaryInputStream) {
        self.stream = stream
    }

    func read() throws -> TypedData {
        let type:TypeType = TypeType(bigEndian:try stream.read())
        let length:LengthType = LengthType(bigEndian:try stream.read())
        let buffer:DispatchData <Void> = try stream.read(Int(length))
        return TypedData(type:type, data:buffer)
    }
}

func indexTLVBuffer(buffer:UnsafeBufferPointer <Void>) throws -> [(Int, Int)] {
    var index:[(Int, Int)] = []
    let scanner = DataScanner(buffer: buffer.toUnsafeBufferPointer())
    while scanner.atEnd == false {
        let _:UInt16 = try scanner.scan()
        let length = Int(UInt16(networkEndian:try scanner.scan()!))
        let offset = scanner.current
        scanner.current += length
        index.append((offset, length))
    }
    return index
}


