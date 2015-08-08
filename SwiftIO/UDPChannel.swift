//
//  UDPMavlinkReceiver.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 4/22/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Foundation
import Darwin

import SwiftUtilities

public struct Datagram {
    public let from:Address
    public let timestamp:Timestamp
    public let buffer:Buffer <Void>

    public init(from:Address, timestamp:Timestamp = Timestamp(), buffer:Buffer <Void>) {
        self.from = from
        self.timestamp = timestamp
        self.buffer = buffer
    }
}

extension Datagram: CustomStringConvertible {
    public var description: String {
        return "Datagram(from:\(from), timestamp:\(timestamp): buffer:\(buffer.length) bytes)"
    }
}

// MARK: -

public var debugLog:(AnyObject? -> Void)? = {
    if let value = $0 {
        print(value)
        }
    }

// MARK: -

/**
 *  A GCD based UDP listener.
 */
public class UDPChannel {

    public var address:Address
    public var readHandler:(Datagram -> Void)? = loggingReadHandler
    public var errorHandler:(ErrorType -> Void)? = loggingErrorHandler

    private var resumed:Bool = false
    private var queue:dispatch_queue_t!
    private var source:dispatch_source_t!
    private var socket:Int32!

    public init(address:Address) throws {
        self.address = address
    }

    public convenience init(hostname:String = "0.0.0.0", port:Int16, family:ProtocolFamily? = nil, readHandler:(Datagram -> Void)? = nil) throws {
        let addresses = try Address.addresses(hostname, service:"\(port)", `protocol`: .UDP, family: family)
        try self.init(address:addresses[0])
        if let readHandler = readHandler {
            self.readHandler = readHandler
        }
    }

    public func resume() throws {
        debugLog?("Resuming")

        socket = Darwin.socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket >= 0 else {
            throw Error.generic("socket() failed")
        }

        var reuseSocketFlag:Int = 1
        let result = Darwin.setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, &reuseSocketFlag, socklen_t(sizeof(Int)))
        guard result == 0 else {
            cleanup()
            throw Error.generic("setsockopt() failed")
        }

        queue = dispatch_queue_create("io.schwa.SwiftIO.UDP", DISPATCH_QUEUE_CONCURRENT)
        guard queue != nil else {
            cleanup()
            throw Error.generic("dispatch_queue_create() failed")
        }

        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(socket), 0, queue)
        guard source != nil else {
            cleanup()
            throw Error.generic("dispatch_source_create() failed")
        }

        dispatch_source_set_cancel_handler(source) {
            [weak self] in
            guard let strong_self = self else {
                return
            }

            debugLog?("Cancel handler")
            strong_self.cleanup()
            strong_self.resumed = false
        }

        dispatch_source_set_event_handler(source) {
            [weak self] in
            guard let strong_self = self else {
                return
            }

            do {
                try strong_self.read()
            }
            catch let error {
                strong_self.errorHandler?(error)
            }
        }

        dispatch_source_set_registration_handler(source) {
            [weak self] in
            guard let strong_self = self else {
                return
            }

            let sockaddr = strong_self.address.addr
            let result = Darwin.bind(strong_self.socket, sockaddr.baseAddress, socklen_t(sockaddr.length))
            guard result == 0 else {
                strong_self.errorHandler?(Error.generic("bind() failed"))
                try! strong_self.cancel()
                return
            }
            strong_self.resumed = true
            debugLog?("Listening on \(strong_self.address)")
        }

        dispatch_resume(source)
    }

    public func cancel() throws {
        if resumed == true {
            assert(source != nil, "Cancel called with source = nil.")
            dispatch_source_cancel(source)
        }
    }

    public func send(data:NSData, address:Address! = nil, writeHandler:((Bool,Error?) -> Void)? = loggingWriteHandler) throws {
        precondition(queue != nil, "Cannot send data without a queue")
        precondition(resumed == true, "Cannot send data on unresumed queue")

        dispatch_async(queue) {

            [weak self] in
            guard let strong_self = self else {
                return
            }

            debugLog?("Send")

            let address:Address = address ?? strong_self.address
            let sockaddr = address.addr
            let result = Darwin.sendto(strong_self.socket, data.bytes, data.length, 0, sockaddr.baseAddress, socklen_t(sockaddr.length))
            if result == data.length {
                writeHandler?(true, nil)
            }
            else if result < 0 {
                writeHandler?(false, Error.generic("sendto() failed"))
            }
            if result < data.length {
                writeHandler?(false, Error.generic("sendto() failed"))
            }
        }
    }

    internal func read() throws {

        // TODO: There are two (buffer, address) data mallocs per read() - this is somewhat unnecessary.

        let data:NSMutableData! = NSMutableData(length: 4096)

        var addressData = Array <Int8> (count:Int(SOCK_MAXADDRLEN), repeatedValue:0)
        let (result, address) = addressData.withUnsafeMutableBufferPointer() {
            (inout ptr:UnsafeMutableBufferPointer <Int8>) -> (Int, Address?) in
            var addrlen:socklen_t = socklen_t(SOCK_MAXADDRLEN)
            let result = Darwin.recvfrom(socket, data.mutableBytes, data.length, 0, UnsafeMutablePointer<sockaddr> (ptr.baseAddress), &addrlen)
            guard result >= 0 else {
                return (result, nil)
            }
            let address = try! Address(addr: UnsafeMutablePointer<sockaddr> (ptr.baseAddress), addrlen: addrlen)
            return (result, address)
        }

        guard result >= 0 else {
            let error = Error.generic("recvfrom() failed")
            errorHandler?(error)
            throw error
        }

        data.length = result
        let datagram = Datagram(from: address!, timestamp: Timestamp(), buffer: Buffer <Void> (data:data))
        readHandler?(datagram)
    }

    internal func cleanup() {
        if let socket = self.socket {
            Darwin.close(socket)
        }
        self.socket = nil
        self.queue = nil
        self.source = nil
    }
}
