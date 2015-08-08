//
//  AddressTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import XCTest

import SwiftIO

class AddressTests: XCTestCase {
    func testLocahost() {
        let address = try! Address(string: "127.0.0.1:80")
        XCTAssertEqual(address.hostname, "localhost")
        XCTAssertEqual(address.protocolFamily, .INET)
        XCTAssertEqual(address.port, 80)
        XCTAssertEqual(address.service, "http")
        XCTAssertEqual(String(address), "127.0.0.1:80")
    }

    func testLocahost6() {
        let address = try! Address(string: "localhost:80", family:.INET6)
        XCTAssertEqual(address.hostname, "localhost")
        XCTAssertEqual(address.protocolFamily, .INET6)
        XCTAssertEqual(address.port, 80)
        XCTAssertEqual(address.service, "http")
        XCTAssertEqual(String(address), "[::]:80")
    }

}
