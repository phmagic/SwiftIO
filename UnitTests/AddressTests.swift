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
        let address = try! Address(address: "127.0.0.1")
        XCTAssertEqual(String(address), "127.0.0.1")
    }

    func testLocahost2() {
        let address = try! Address(address: "localhost")
        XCTAssertEqual(String(address), "127.0.0.1")
    }

    func testLocahost3() {
        let addresses = try! Address.addresses("localhost")
        print(addresses)
    }

}
