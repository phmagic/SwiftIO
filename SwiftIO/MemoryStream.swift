//
//  MemoryStream.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

public class MemoryStream: BinaryInputStream, BinaryOutputStream {
    internal var mutableData:NSMutableData = NSMutableData() // TODO: Use DispatchData

    var head:Int = 0
    var remaining:Int {
        return mutableData.length - head
    }

    public init() {
    }

    public init(buffer:UnsafeBufferPointer <Void>) {
        mutableData = NSMutableData(bytes: buffer.baseAddress, length: buffer.length)
    }

    public var buffer:UnsafeBufferPointer <Void> {
        return mutableData.toUnsafeBufferPointer()
    }

    public func read(length:Int) throws -> DispatchData <Void> {
        if length > remaining {
            throw Error.generic("Not enough space (requesting \(length) bytes, only \(remaining) bytes remaining")
        }

        let result = DispatchData <Void> (start:buffer.baseAddress.advancedBy(head), count:length)
        head += length
        return result
    }

    public func write(buffer:UnsafeBufferPointer <Void>) throws {
        mutableData.appendBytes(buffer.baseAddress, length: buffer.count)
        head = mutableData.length
    }

    public var data:NSData {
        return mutableData
    }
}
