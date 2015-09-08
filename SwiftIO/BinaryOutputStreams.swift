//
//  BinaryOutputStreams.swift
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

public protocol BinaryOutputStream {
   func write(buffer:UnsafeBufferPointer <Void>) throws
}

// MARK: -

public protocol BinaryOutputStreamable {
    func writeTo <Target:BinaryOutputStream> (stream:Target) throws
}

public extension BinaryOutputStream {
    func write <Target:BinaryOutputStreamable> (value:Target) throws {
        try value.writeTo(self)
    }
}

// MARK: -

extension DispatchData: BinaryOutputStreamable {
    public func writeTo <Target:BinaryOutputStream> (stream:Target) throws {
        apply() {
            (range, buffer) in
            try! stream.write(buffer.toUnsafeBufferPointer())
            return true
        }
    }
}


extension Int32: BinaryOutputStreamable {
    public func writeTo <Target:BinaryOutputStream> (stream:Target) throws {
        var value = self
        let buffer = withUnsafePointer(&value) {
            (pointer:UnsafePointer <Int32>) -> UnsafeBufferPointer <Void> in
            return UnsafeBufferPointer(start: pointer, count: sizeof(Int32))
        }
        try stream.write(buffer)
    }
}

extension NSData: BinaryOutputStreamable {
    public func writeTo <Target:BinaryOutputStream> (stream:Target) throws {
        let buffer = UnsafeBufferPointer <Void> (start: bytes, count: length)
        try stream.write(buffer)
    }
}

// MARK: -

public extension BinaryOutputStream {

    func write(string:String, appendNewline: Bool = false) throws {
        let string = appendNewline == true ? string : string + "\n"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let buffer = UnsafeBufferPointer <Void> (start:data.bytes, count:data.length)
        try write(buffer)
    }
}

// MARK: -

