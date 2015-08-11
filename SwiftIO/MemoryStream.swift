//
//  MemoryStream.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

public class MemoryStream: BinaryInputStream, BinaryOutputStream {
    internal var mutableData:NSMutableData = NSMutableData()

    var head:Int = 0
    var remaining:Int {
        return mutableData.length - head
    }

    public init() {
    }

    public init(buffer:Buffer <Void>) {
        mutableData = NSMutableData(bytes: buffer.baseAddress, length: buffer.length)
    }

    public var buffer:Buffer <Void> {
        return Buffer <Void> (data: mutableData)
    }

    public func read(length:Int) throws -> Buffer <Void> {
        if length > remaining {
            throw Error.generic("Not enough space (requesting \(length) bytes, only \(remaining) bytes remaining")
        }

        let result = Buffer <Void> (pointer:buffer.baseAddress.advancedBy(head), length:length)
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
