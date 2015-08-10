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
        XCTAssertEqual(address.address, "127.0.0.1")
    }

    func testLocahostIPV4() {
        let address = try! Address(address: "localhost", family:.INET)
        XCTAssertEqual(address.address, "127.0.0.1")
    }

    func testLocahostIPV6() {
        let address = try! Address(address: "localhost", family:.INET6)
        XCTAssertEqual(address.address, "::")
    }

    func testLocahost3() {
        let addresses:[(Address,InetProtocol,ProtocolFamily,String?)] = try! Address.addresses("apple.com")
        addresses.forEach() { print($0) }
    }

}
