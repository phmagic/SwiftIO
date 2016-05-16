//
//  ServiceScannerTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/16/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import XCTest

@testable import SwiftIO

class ServiceScannerTests: XCTestCase {
    
    func testIPV4Address1() {
        let scanner = NSScanner(string: "255.255.255.255")
        var address: String?
        let result = scanner.scanIPV4Address(&address)
        XCTAssertTrue(result)
        XCTAssertEqual(address, "255.255.255.255")
    }
    
    func testIPV4Address2() {
        let scanner = NSScanner(string: "X.255.255.255")
        var address: String?
        let result = scanner.scanIPV4Address(&address)
        XCTAssertFalse(result)
        XCTAssertNil(address)
    }

    func testScanAddressGood() {
        let inputs:[(String, String?, String?)] = [
            ("[::ffff:0.0.0.0]:14550", "::ffff:0.0.0.0", "14550"),
            ("[::ffff:0.0.0.0]", "::ffff:0.0.0.0", nil),
            ("0.0.0.0:14550", "0.0.0.0", "14550"),
            ("0.0.0.0", "0.0.0.0", nil),
            ("localhost", "localhost", nil),
//            ("localhost:14550", "localhost", "14550"),
        ]

        for input in inputs {
            var address: String?
            var port: String?
            let result = scanAddress(input.0, address: &address, port: &port)

            XCTAssertTrue(result)
            XCTAssertEqual(address, input.1)
            XCTAssertEqual(port, input.2)
        }
    }
    
    func testScanAddressBad() {
        let inputs = [
            "::ffff:0.0.0.0",
        ]

        for input in inputs {
            var address: String? = nil
            var port: String? = nil
            let result = scanAddress(input, address: &address, port: &port)
            
            XCTAssertFalse(result)
            XCTAssertNil(address)
            XCTAssertNil(port)
        }
    }
    
}



