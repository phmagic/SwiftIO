//
//  Inet+UtilitiesTests.swift
//  SwiftIO
//
//  Created by Bart Cone on 1/1/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import XCTest

@testable
import SwiftIO

class Inet_UtilitiesTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_NtopWrapperFor_IPv4() {
        let ipv4 = "255.255.255.255"
        let address = try! Address(address: ipv4, `protocol`: InetProtocol.TCP, family: ProtocolFamily.INET)
        var converted: String = ""

        if case .INET(var addr) = address.internalAddress {
            converted = try! inet_ntop(addressFamily: address.addressFamily, address: &addr)
        }

        XCTAssertEqual(ipv4, converted, "Addresses not equal")
    }

    func DISABLED_test_NtopWrapperFor_IPv6() {
        let ipv6 = "2001:db8:8714:3a90::12"
        let address = try! Address(address: ipv6, `protocol`: InetProtocol.TCP, family: ProtocolFamily.INET6)
        var converted: String = ""

        if case .INET6(var addr) = address.internalAddress {
            converted = try! inet_ntop(addressFamily: address.addressFamily, address: &addr)
        }

        XCTAssertEqual(ipv6, converted, "Addresses not equal")
    }

}
