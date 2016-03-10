//
//  Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/10/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin
import Foundation

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
