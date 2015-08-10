//
//  NetworkEndian.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/10/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

public extension UInt16 {
    init(networkEndian value:UInt16) {
        self = UInt16(bigEndian: value)
    }
    var networkEndian: UInt16 {
        return bigEndian
    }
}

public extension UInt32 {
    init(networkEndian value:UInt32) {
        self = UInt32(bigEndian: value)
    }
    var networkEndian: UInt32 {
        return bigEndian
    }
}

public extension UInt64 {
    init(networkEndian value:UInt64) {
        self = UInt64(bigEndian: value)
    }
    var networkEndian: UInt64 {
        return bigEndian
    }
}

public extension Int16 {
    init(networkEndian value:Int16) {
        self = Int16(bigEndian: value)
    }
    var networkEndian: Int16 {
        return bigEndian
    }
}

public extension Int32 {
    init(networkEndian value:Int32) {
        self = Int32(bigEndian: value)
    }
    var networkEndian: Int32 {
        return bigEndian
    }
}

public extension Int64 {
    init(networkEndian value:Int64) {
        self = Int64(bigEndian: value)
    }
    var networkEndian: Int64 {
        return bigEndian
    }
}