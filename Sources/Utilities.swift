//
//  Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/10/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin

internal extension timeval {
    init(time: NSTimeInterval) {
        tv_sec = __darwin_time_t(time)
        tv_usec = __darwin_suseconds_t((time - floor(time)) * NSTimeInterval(USEC_PER_SEC))
    }

    var timeInterval: NSTimeInterval {
        return NSTimeInterval(tv_sec) + NSTimeInterval(tv_usec) / NSTimeInterval(USEC_PER_SEC)
    }
}

internal extension timeval64 {
    init(time: NSTimeInterval) {
        tv_sec = __int64_t(time)
        tv_usec = __int64_t((time - floor(time)) * NSTimeInterval(USEC_PER_SEC))
    }

    var timeInterval: NSTimeInterval {
        return NSTimeInterval(tv_sec) + NSTimeInterval(tv_usec) / NSTimeInterval(USEC_PER_SEC)
    }

}

internal func unsafeCopy <DST, SRC> (destination destination: UnsafeMutablePointer <DST>, source: UnsafePointer <SRC>) {
    let length = min(sizeof(DST), sizeof(SRC))
    unsafeCopy(destination: destination, source: source, length: length)
}

internal func unsafeCopy <DST> (destination destination: UnsafeMutablePointer <DST>, source: UnsafePointer <Void>, length: Int) {
    precondition(sizeof(DST) >= length)
    memcpy(destination, source, length)
}

internal extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}
