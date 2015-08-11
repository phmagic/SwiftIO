//
//  DatagramTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/10/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import XCTest

import SwiftIO
import SwiftUtilities

class DatagramTests: XCTestCase {

    func testExample() {
        let address = try! Address(address: "localhost")

        let port:UInt16 = 12345
        let buffer = Buffer <Void> (data:"Hello world".dataUsingEncoding(NSUTF8StringEncoding)!)
        let datagram = Datagram(from: (address, port), buffer: buffer)
        let encodedData = try! NSData(streamable: datagram)
        encodedData.buffer
        let stream = MemoryStream(buffer: Buffer <Void> (data:encodedData))
        let decodedDatagram = try! Datagram.readFrom(stream)

        XCTAssertEqual(datagram, decodedDatagram)
    }

}

extension NSData {
    convenience init(streamable:BinaryOutputStreamable) throws {
        let stream = MemoryStream()
        try streamable.writeTo(stream)
        self.init(data:stream.data)
    }
}

//extension Datagram {
//
//    public static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Datagram {
//    }
//
