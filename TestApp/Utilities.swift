//
//  Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

struct Async {
    static func main(closure:() -> Void) {
        dispatch_async(dispatch_get_main_queue(), closure)
    }
}