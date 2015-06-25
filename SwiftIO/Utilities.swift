//
//  MavLink.swift
//  MavlinkTest
//
//  Created by Jonathan Wight on 3/29/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Foundation

/**
 *  A wrapper around CFAbsoluteTime
 *
 *  CFAbsoluteTime is just a (indirect) wrapper around a Double. By wrapping it ourselves in a struct we're able to extend it.
 */
public struct Timestamp {
    public let absoluteTime:CFAbsoluteTime

    init() {
        absoluteTime = CFAbsoluteTimeGetCurrent()
    }
}

extension Timestamp: CustomStringConvertible {
    public var description: String {
        return "\(absoluteTime)"
    }
}


// MARK: -

public func convert <T, U>(pointer:UnsafeMutablePointer <T>) -> UnsafeMutablePointer <U> {
    return UnsafeMutablePointer <U> (pointer)
}

public func hexNibbleToInt(nibble:Int8) -> UInt8? {
    switch nibble {
        case 0x30 ... 0x39:
            return UInt8(nibble) - 0x30
        case 0x41 ... 0x46:
            return UInt8(nibble) - 0x41 + 0x0A
        case 0x61 ... 0x66:
            return UInt8(nibble) - 0x61 + 0x0A
        default:
            return nil
    }
}

public extension String {
    func withCString<Result>(@noescape f: UnsafeBufferPointer<Int8> -> Result) -> Result {
        return withCString() {
            (ptr: UnsafePointer<Int8>) -> Result in
            let buffer = UnsafeBufferPointer <Int8> (start:ptr, count:Int(strlen(ptr)))
            return f(buffer)
        }
    }
}

public extension NSData {

    convenience init?(hexString string:String) {
        let outputBuffer = string.withCString() {
            (buffer: UnsafeBufferPointer <Int8>) -> UnsafeMutableBufferPointer <UInt8>! in
            if let outputBuffer = UnsafeMutableBufferPointer <UInt8>.alloc(buffer.count / 2) {
                var P = outputBuffer.baseAddress
                var hiNibble = true
                for hexNibble in buffer {
                    if hexNibble == 0x20 {
                        continue
                    }
                    if let nibble = hexNibbleToInt(hexNibble) {
                        if hiNibble {
                            P.memory = nibble << 4
                            hiNibble = false
                        }
                        else {
                            P.memory |= nibble
                            hiNibble = true
                            P = P.advancedBy(1)
                        }
                    }
                    else {
                        return nil
                    }
                }
                return outputBuffer
            }
            else {
                return nil
            }
        }

        if let outputBuffer = outputBuffer {
            self.init(bytesNoCopy:outputBuffer.baseAddress, length:outputBuffer.count, freeWhenDone:true)
        }
        else {
            self.init()
            return nil
        }
    }
}

public extension NSData {
    var buffer:UnsafeBufferPointer <Void> {
        get {
            return UnsafeBufferPointer <Void> (start: bytes, count: length)
        }
    }
}

public func log2(v:Int) -> Int {
    return Int(log2(Float(v)))
}

public extension UInt8 {
    var asHex:String {
        get {
            return intToHex(Int(self))
        }
    }
}

public extension UInt16 {
    var asHex:String {
        get {
            return intToHex(Int(self))
        }
    }
}

public func intToHex(value:Int, skipLeadingZeros:Bool = true, addPrefix:Bool = false, lowercase:Bool = false) -> String {
    var s = ""
    var skipZeros = skipLeadingZeros
    let digits = log2(Int.max) / 8
    for var n:Int = digits; n >= 0; --n {
        let shift = n * 4
        let nibble = (value >> shift) & 0xF
        if !(skipZeros == true && nibble == 0) {
            s += nibbleAsHex(nibble, lowercase:lowercase)
            skipZeros = false
        }
    }
    return addPrefix ? "0x" + s : s
}

public func nibbleAsHex(nibble:Int, lowercase:Bool = false) -> String {
    let uppercaseDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    let lowercaseDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    return lowercase ? lowercaseDigits[nibble] : uppercaseDigits[nibble]
}

// MARK: -

// Following all marked private because we can't make public extensions on generic types.

private extension UnsafeBufferPointer {
    var asHex:String {
        get {
            let buffer:UnsafeBufferPointer <UInt8> = asUnsafeBufferPointer()
            let hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
            return "".join(buffer.map {
                let hiNibble = Int($0) >> 4
                let loNibble = Int($0) & 0b1111
                return hex[hiNibble] + hex[loNibble]
            })
        }
    }
}

private extension UnsafeBufferPointer {
    func asUnsafeBufferPointer <U>() -> UnsafeBufferPointer <U> {
        let start = UnsafePointer <U> (baseAddress)
        let count = (self.count * max(sizeof(T), 1)) / max(sizeof(U), 1)
        return UnsafeBufferPointer <U> (start:start, count:count)
    }
}

private extension UnsafeMutableBufferPointer {
    static func alloc(count:size_t) -> UnsafeMutableBufferPointer <T>? {
        let ptr = UnsafeMutablePointer <T> (calloc(count, sizeof(T)))
        if ptr == nil {
            return nil
        }
        let buffer = UnsafeMutableBufferPointer <T> (start:ptr, count:count)
        return buffer
    }
}

private extension UnsafeBufferPointer {
    subscript (range:Range <Int>) -> UnsafeBufferPointer <T> {
        get {
            return UnsafeBufferPointer <T> (start: baseAddress + range.startIndex, count:range.endIndex - range.startIndex)
        }
    }
}
