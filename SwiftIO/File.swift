//
//  File.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 9/29/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

internal func loggingReadHandler(datagram: Datagram) {
    debugLog?("READ")
}

internal func loggingErrorHandler(error: ErrorType) {
    debugLog?("ERROR: \(error)")
}

internal func loggingWriteHandler(success: Bool, error: Error?) {
    if success {
        debugLog?("WRITE")
    }
    else {
        loggingErrorHandler(error!)
    }
}
