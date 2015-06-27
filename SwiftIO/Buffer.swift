//
//  Buffer.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Foundation

/**
 *  A typed memory buffer
 *
 *  NSData and UnsafeBufferPointer have a bastard love child.
 */
public struct Buffer <T> {

    // TODO: Add more UnsafeBufferPointer APIs and protocol adoptions

    public var data:NSData

    init() {
        data = NSData()
    }

    public var length:Int {
        return data.length
    }

    public var count:Int {
        return data.length / Buffer <T>.elementSize
    }

    public static var elementSize:Int {
        return max(sizeof(T), 1)
    }

    public init(data:NSData) {
        assert(data.length == 0 || data.length >= Buffer <T>.elementSize)
        self.data = data
    }

    public init(pointer:UnsafePointer <T>, length:Int) {
        assert(length >= Buffer <T>.elementSize)
        self.data = NSData(bytes: pointer, length: length)
    }

    public init(bufferPointer:UnsafeBufferPointer <T>) {
        data = NSData(bytes: bufferPointer.baseAddress, length: bufferPointer.count * Buffer <T>.elementSize)
    }

    public var pointer:UnsafePointer <T> {
        return UnsafePointer <T> (data.bytes)
    }

    public var bufferPointer:UnsafeBufferPointer <T> {
        let count = data.length / Buffer <T>.elementSize
        return UnsafeBufferPointer <T> (start:self.pointer, count:count)
    }
}
