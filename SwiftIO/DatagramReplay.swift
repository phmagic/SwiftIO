//
//  DatagramReplay.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

public class MemoryStream: BinaryInputStream, BinaryOutputStream {
    internal var mutableData:NSMutableData = NSMutableData()

    var head:Int = 0
    var remaining:Int {
        return mutableData.length - head
    }

    init() {
    }

    init(buffer:Buffer <Void>) {
        mutableData = NSMutableData(bytes: buffer.pointer, length: buffer.length)
    }

    public var buffer:Buffer <Void> {
        return Buffer <Void> (data: mutableData)
    }

    public func read(length:Int) throws -> Buffer <Void> {
        if length > remaining {
            throw Error.generic("Not enough space.")
        }

        let result = Buffer <Void> (pointer:buffer.pointer.advancedBy(head), length:length)
        head += length
        return result

    }


    public func write(buffer:UnsafeBufferPointer <Void>) throws {
        mutableData.appendBytes(buffer.baseAddress, length: buffer.count)
        head = mutableData.length
    }
}


enum Type: Int {
    case datagram
}

extension Type: BinaryInputStreamable, BinaryOutputStreamable {

    static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Type {
        let type:Int32 = try stream.read()
        if let type = Type(rawValue:Int(type)) {
            return type
        }
        else {
            throw Error.generic("Could not create a type \(type)")
        }
    }

    func writeTo <T:BinaryOutputStream> (stream:T) throws {
        let value = Int32(self.rawValue)
        try stream.write(value)
    }
}

public func loggingDatagramHandler() throws -> Datagram -> Void {
    let stream = FileStream(url: NSURL(fileURLWithPath: "/Users/schwa/Desktop/test.log"))
    try stream.open()
    return {
        (datagram:Datagram) -> Void in
        try! stream.write(datagram)
    }
}

extension Datagram: BinaryInputStreamable, BinaryOutputStreamable {

    public static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Datagram {

        let typedData:TypedData <Type> = try stream.read()
        if typedData.type != .datagram {
            throw Error.generic("Oops")
        }

        let payload = MemoryStream(buffer: typedData.buffer)

        let jsonLength:Int32 = try payload.read()
        let jsonBuffer:Buffer <Void> = try payload.read(Int(jsonLength))
        let jsonData = jsonBuffer.data
        let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions()) as! [String:AnyObject]

        guard let from = json["from"] as? String else {
            throw Error.generic("Could not get from address")
        }

        let dataLength:Int32 = try payload.read()
        let buffer:Buffer <Void> = try payload.read(Int(dataLength))
        let datagram = Datagram(from:Address(string: from), buffer: buffer)

        return datagram
    }


    public func writeTo <Stream:BinaryOutputStream> (stream:Stream) throws {

        let payload = MemoryStream()

        let metadata:[String:AnyObject] = [
            "from": String(from),
            "timestamp": String(timestamp),
        ]
        let json = try! NSJSONSerialization.dataWithJSONObject(metadata, options: NSJSONWritingOptions())
        try! payload.write(Int32(json.length))
        try! payload.write(json)


        try! payload.write(Int32(buffer.length))
        try! payload.write(buffer.bufferPointer)

        let typedData = TypedData(type:Type.datagram, buffer:payload.buffer)

        try! stream.write(typedData)
    }
}



