//
//  AddressTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/8/15.
//
//  Copyright (c) 2014, Jonathan Wight
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import XCTest

@testable import SwiftIO

class AddressTests: XCTestCase {

    func testInterfaces() {
        let addresses = try! Address.addressesForInterfaces()["lo0"]![0] // TODO: a bit crap
        XCTAssertEqual(addresses.address, "127.0.0.1")
    }

    func testIPV4Address() {

        let address = try! Address(address: "127.0.0.1", port: 1234)
        XCTAssertEqual(address.address, "127.0.0.1")
        XCTAssertEqual(String(address), "127.0.0.1:1234")
        XCTAssertEqual(address.port, 1234)
        XCTAssertEqual(address.family, ProtocolFamily.INET)

        let addr = address.to_in_addr()!
        XCTAssertEqual(addr.s_addr, UInt32(0x7F000001).networkEndian)

        let sockaddr = address.to_sockaddr()
        XCTAssertEqual(sockaddr.sa_family, sa_family_t(PF_INET))
        XCTAssertEqual(sockaddr.sa_len, 16)

        let sockaddrIPV4 = sockaddr.to_sockaddr_in()
        XCTAssertEqual(sockaddrIPV4.sin_port, UInt16(1234).networkEndian)
        XCTAssertEqual(sockaddrIPV4.sin_addr.s_addr, UInt32(0x7F000001).networkEndian)

        let octets = address.IPV4Octets
        XCTAssertEqual(octets.0, 0x7f)
        XCTAssertEqual(octets.1, 0x00)
        XCTAssertEqual(octets.2, 0x00)
        XCTAssertEqual(octets.3, 0x01)

        let other = Address(addr: sockaddrIPV4.sin_addr, port: address.port)
        XCTAssertEqual(address, other)
        XCTAssertFalse(address < other)


    }



}

public extension Address {

    var IPV4Octets: (UInt8, UInt8, UInt8, UInt8) {
        let sockaddr = to_sockaddr()
        let sockaddrIPV4 = sockaddr.to_sockaddr_in()
        let address = UInt32(networkEndian: sockaddrIPV4.sin_addr.s_addr)
        return (
            UInt8((address >> 24) & 0xFF),
            UInt8((address >> 16) & 0xFF),
            UInt8((address >> 8) & 0xFF),
            UInt8(address & 0xFF)
        )
    }

}
