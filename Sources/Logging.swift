//
//  Logging.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 9/29/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

public var logHandler: (Any? -> Void)? = nil

public class Logger {
    public func debug(subject: Any?) {
        logHandler?(subject)
    }
}

public let log: Logger? = Logger()

internal func loggingReadHandler(datagram: Datagram) {
    log?.debug(String(datagram))
}

internal func loggingErrorHandler(error: ErrorType) {
    log?.debug("ERROR: \(error)")
}

internal func loggingWriteHandler(success: Bool, error: ErrorType?) {
    if success {
        log?.debug("WRITE")
    }
    else {
        loggingErrorHandler(error!)
    }
}
