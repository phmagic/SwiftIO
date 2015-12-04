//
//  MemoryStream.swift
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

public class MemoryStream: BinaryInputStream, BinaryOutputStream {

    public var endianess = Endianess.native


    internal var mutableData: NSMutableData = NSMutableData() // TODO: Use DispatchData

    var head: Int = 0
    var remaining: Int {
        return mutableData.length - head
    }

    public init() {
    }

    public init(buffer: UnsafeBufferPointer <Void>) {
        mutableData = NSMutableData(bytes: buffer.baseAddress, length: buffer.length)
    }

    public var buffer: UnsafeBufferPointer <Void> {
        return mutableData.toUnsafeBufferPointer()
    }

    public func read(length: Int) throws -> DispatchData <Void> {
        if length > remaining {
            throw Error.Generic("Not enough space (requesting \(length) bytes, only \(remaining) bytes remaining")
        }

        let result = DispatchData <Void> (start: buffer.baseAddress.advancedBy(head), count: length)
        head += length
        return result
    }

    public func write(buffer: UnsafeBufferPointer <Void>) throws {
        mutableData.appendBytes(buffer.baseAddress, length: buffer.count)
        head = mutableData.length
    }

    public var data: NSData {
        return mutableData
    }

    public func rewind() {
        head = 0
    }
}
