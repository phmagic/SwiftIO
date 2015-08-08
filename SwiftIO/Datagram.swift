//
//  Datagram.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

public struct Datagram {
    public let from:(Address, UInt16)
    public let timestamp:Timestamp
    public let buffer:Buffer <Void>

    public init(from:(Address,UInt16), timestamp:Timestamp = Timestamp(), buffer:Buffer <Void>) {
        self.from = from
        self.timestamp = timestamp
        self.buffer = buffer
    }
}

// MARK: -

extension Datagram: CustomStringConvertible {
    public var description: String {
        return "Datagram(from:\(from), timestamp:\(timestamp): buffer:\(buffer.length) bytes)"
    }
}

// MARK: -

extension Datagram: BinaryInputStreamable, BinaryOutputStreamable {

    public static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Datagram {

        let jsonLength:Int32 = try stream.read()
        let jsonBuffer:Buffer <Void> = try stream.read(Int(jsonLength))
        let jsonData = jsonBuffer.data
        let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions()) as! [String:AnyObject]

        guard let address = json["address"] as? String else {
            throw Error.generic("Could not get from address")
        }

        guard let port = json["port"] as? UInt16 else {
            throw Error.generic("Could not get from address")
        }

        let dataLength:Int32 = try stream.read()
        let buffer:Buffer <Void> = try stream.read(Int(dataLength))
        let datagram = try Datagram(from:(Address(address:address), port), buffer: buffer)

        return datagram
    }


    public func writeTo <Stream:BinaryOutputStream> (stream:Stream) throws {

        let stream = MemoryStream()

        let metadata:[String:AnyObject] = [
            "address": String(from.0),
            "port": String(from.1),
            "timestamp": String(timestamp),
        ]
        let json = try NSJSONSerialization.dataWithJSONObject(metadata, options: NSJSONWritingOptions())
        try stream.write(Int32(json.length))
        try stream.write(json)
        try stream.write(Int32(buffer.length))
        try stream.write(buffer.bufferPointer)
    }
}
