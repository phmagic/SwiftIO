//
//  Datagram.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

public struct Datagram {
    public let from:(Address, UInt16)
    public let timestamp:Timestamp
    public let data:DispatchData <Void>

    public init(from:(Address,UInt16), timestamp:Timestamp = Timestamp(), data:DispatchData <Void>) {
        self.from = from
        self.timestamp = timestamp
        self.data = data
    }
}

// MARK: -

extension Datagram: Equatable {
}

public func ==(lhs: Datagram, rhs: Datagram) -> Bool {

    if lhs.from.0 != rhs.from.0 {
        return false
    }
    if lhs.from.1 != rhs.from.1 {
        return false
    }
    if lhs.timestamp != rhs.timestamp {
        return false
    }
    if lhs.data != rhs.data {
        return false
    }

    return true
}

// MARK: -

extension Datagram: CustomStringConvertible {
    public var description: String {
        return "Datagram(from:\(from), timestamp:\(timestamp): data:\(data.length) bytes)"
    }
}
