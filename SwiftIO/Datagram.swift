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

extension Datagram: Equatable {
}

public func ==(lhs: Datagram, rhs: Datagram) -> Bool {

    if lhs.from.0 != rhs.from.0 {
        return false
    }
    if lhs.from.1 != rhs.from.1 {
        return false
    }
    if lhs.timestamp != rhs.timestamp {
        return false
    }
    if lhs.buffer != rhs.buffer {
        return false
    }

    return true
}

// MARK: -

extension Datagram: CustomStringConvertible {
    public var description: String {
        return "Datagram(from:\(from), timestamp:\(timestamp): buffer:\(buffer.length) bytes)"
    }
}

extension Datagram: CustomReflectable {
    public func customMirror() -> Mirror {
        return Mirror(self, children: [
            "from": from,
            "timestamp": timestamp,
            "buffer": buffer,
        ])
    }
}

// MARK: -

extension Datagram: BinaryInputStreamable, BinaryOutputStreamable {

    public static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Datagram {

        let jsonLength = Int32(networkEndian:try stream.read())
        let jsonBuffer:Buffer <Void> = try stream.read(Int(jsonLength))
        let jsonData = jsonBuffer.data
        let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions()) as! [String:AnyObject]

        guard let address = json["address"] as? String else {
            throw Error.generic("Could not get from address")
        }

        guard let port = json["port"] as? Int else {
            throw Error.generic("Could not get from port")
        }

        guard let absoluteTime = json["timestamp"] as? Double else {
            throw Error.generic("Could not get from port")
        }

        // TODO: timestamp

        let dataLength = Int32(networkEndian:try stream.read())
        let buffer:Buffer <Void> = try stream.read(Int(dataLength))
        let datagram = try Datagram(from:(Address(address:address), UInt16(port)), timestamp:Timestamp(absoluteTime: absoluteTime), buffer: buffer)

        return datagram
    }


    public func writeTo <Stream:BinaryOutputStream> (stream:Stream) throws {

        let metadata:[String:AnyObject] = [
            "address": from.0.address,
            "port": Int(from.1),
            "timestamp": timestamp.absoluteTime,
        ]
        let json = try NSJSONSerialization.dataWithJSONObject(metadata, options: NSJSONWritingOptions())
        try stream.write(Int32(networkEndian:Int32(json.length)))
        try stream.write(json)
        try stream.write(Int32(networkEndian:Int32(buffer.length)))
        try stream.write(buffer.bufferPointer)
    }
}
