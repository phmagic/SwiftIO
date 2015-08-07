//
//  TCPChannel.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/23/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Foundation

import Darwin

// TODO: This is a very very very very early WIP

public class TCPChannel {

    public var address:Address
    public var readHandler:(Void -> Void)? = nil
    public var errorHandler:(Error -> Void)? = loggingErrorHandler

    private var resumed:Bool = false
    private var queue:dispatch_queue_t!
    private var socket:Int32!

    public init(address:Address) {
        self.address = address
    }

    public convenience init(hostname:String = "0.0.0.0", port:Int16, family:ProtocolFamily? = nil, readHandler:(Void -> Void)? = nil) {
        let addresses = Address.addresses(hostname, service:"\(port)", `protocol`: .TCP, family: family)
        self.init(address:addresses[0])
        if let readHandler = readHandler {
            self.readHandler = readHandler
        }
    }

    public func resume() {
        debugLog?("Resuming")

        socket = Darwin.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
        if socket < 0 {
            errorHandler?(Error.generic("socket() failed"))
            return
        }

//let flags = Darwin.fcntl(socket, F_GETFL, 0)
//fcntl(socket, F_SETFL, flags | O_NONBLOCK)

        let sockaddr = address.addr
        let result = Darwin.connect(socket, sockaddr.baseAddress, socklen_t(sockaddr.length))
        if result != 0 {
            cleanup()
            errorHandler?(Error.generic("connect() failed"))
            return
        }

        queue = dispatch_queue_create("io.schwa.SwiftIO.TCP", DISPATCH_QUEUE_CONCURRENT)
        if queue == nil {
            cleanup()
            errorHandler?(Error.generic("dispatch_queue_create() failed"))
            return
        }

    }

    public func cancel() {
    }

    public func send(data:NSData, address:Address! = nil, writeHandler:((Bool,Error?) -> Void)? = loggingWriteHandler) {
        // TODO
    }

    internal func read() {
        // TODO

    }

    internal func cleanup() {
        if let socket = self.socket {
            Darwin.close(socket)
        }
        self.socket = nil
        self.queue = nil
    }
}

// MARK: -

internal func loggingReadHandler(datagram:Datagram) {
    debugLog?("READ")
}

internal func loggingErrorHandler(error:Error) {
    debugLog?("ERROR: \(error)")
}

internal func loggingWriteHandler(success:Bool, error:Error?) {
    if success {
        debugLog?("WRITE")
    }
    else {
        loggingErrorHandler(error!)
    }
}
