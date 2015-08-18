//
//  Datagram+Streams.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/18/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

extension Datagram: BinaryInputStreamable, BinaryOutputStreamable {

    public static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Datagram {

        let jsonLength = Int32(networkEndian:try stream.read())
        guard jsonLength >= 0 else {
            throw Error.generic("Negative length")
        }

        let jsonBuffer:DispatchData <Void> = try stream.read(Int(jsonLength))
        let jsonData = jsonBuffer.data as! NSData
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

        let dataLength = Int32(networkEndian:try stream.read())
        guard dataLength >= 0 else {
            throw Error.generic("Negative length")
        }

        let data:DispatchData <Void> = try stream.read(Int(dataLength))
        let datagram = try Datagram(from:(Address(address:address), UInt16(port)), timestamp:Timestamp(absoluteTime: absoluteTime), data: data)

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
        try stream.write(Int32(networkEndian:Int32(data.length)))
        try stream.write(data)
    }
}
