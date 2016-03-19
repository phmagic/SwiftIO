//
//  Address+Misc.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 3/18/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Foundation

public extension in_addr {
    var octets: (UInt8, UInt8, UInt8, UInt8) {
        let address = UInt32(networkEndian: s_addr)
        return (
            UInt8((address >> 24) & 0xFF),
            UInt8((address >> 16) & 0xFF),
            UInt8((address >> 8) & 0xFF),
            UInt8(address & 0xFF)
        )
    }
}

public extension in6_addr {
    var words: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16) {
        assert(sizeof(in6_addr) == sizeof((UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)))
        var copy = self
        return withUnsafePointer(&copy) {
            let networkWords = UnsafeBufferPointer <UInt16> (start: UnsafePointer <UInt16> ($0), count: 8)
            let words = networkWords.map() { UInt16(networkEndian: $0) }
            return (words[0], words[1], words[2], words[3], words[4], words[5], words[6], words[7])
        }
    }
}
