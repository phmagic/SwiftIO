//
//  UDPMavlinkReceiver.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 4/22/15.
//
//  Copyright (c) 2014, Jonathan Wight
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Darwin
import Dispatch
import Foundation

import SwiftUtilities

/**
 *  A GCD based UDP listener.
 */
public class UDPChannel {

    public let label: String?

    public let address: Address

    public var readHandler: (Datagram -> Void)? = loggingReadHandler
    public var errorHandler: (ErrorType -> Void)? = loggingErrorHandler

    private var resumed: Bool = false
    private let receiveQueue: dispatch_queue_t!
    private let sendQueue: dispatch_queue_t!
    private var source: dispatch_source_t!

    public private(set) var socket: Socket!
    public var configureSocket: (Socket -> Void)?

    // MARK: - Initialization

    public init(label: String? = nil, address: Address, qos: dispatch_qos_class_t = QOS_CLASS_DEFAULT, readHandler: (Datagram -> Void)? = nil) {
        self.label = label
        self.address = address

        assert(address.port != nil)
        if let readHandler = readHandler {
            self.readHandler = readHandler
        }

        let queueAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, 0)

        receiveQueue = dispatch_queue_create("io.schwa.SwiftIO.UDP.receiveQueue", queueAttribute)
        guard receiveQueue != nil else {
            fatalError("dispatch_queue_create() failed")
        }

        sendQueue = dispatch_queue_create("io.schwa.SwiftIO.UDP.sendQueue", queueAttribute)
        guard sendQueue != nil else {
            fatalError("dispatch_queue_create() failed")
        }
    }

    // MARK: - Actions

    public func resume() throws {
        log?.debug("\(self): resume.")

        do {
            socket = try Socket(domain: address.family.rawValue, type: SOCK_DGRAM, protocol: IPPROTO_UDP)

        }
        catch let error {
            cleanup()
            errorHandler?(error)
        }

        configureSocket?(socket)

        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(socket.descriptor), 0, receiveQueue)
        guard source != nil else {
            cleanup()
            throw Error.Generic("dispatch_source_create() failed")
        }

        dispatch_source_set_cancel_handler(source) {
            [weak self] in
            guard let strong_self = self else {
                return
            }

            log?.debug("\(strong_self): Cancel handler.")

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

            do {
                try strong_self.socket.bind(strong_self.address)

                strong_self.resumed = true

                log?.debug("\(strong_self): Listening on \(strong_self.address)")
            }
            catch let error {
                strong_self.errorHandler?(error)

                tryElseFatalError() {
                    try strong_self.cancel()
                }

                return
            }
        }

        dispatch_resume(source)
    }

    public func cancel() throws {
        if resumed == true {
            assert(source != nil, "Cancel called with source = nil.")
            dispatch_source_cancel(source)
        }
    }

    public func send(data: DispatchData <Void>, address: Address! = nil, writeHandler: Result <Void> -> Void) {
        precondition(sendQueue != nil, "Cannot send data without a queue")
        precondition(resumed == true, "Cannot send data on unresumed queue")

        dispatch_async(sendQueue) {
            [weak self] in

            guard let strong_self = self else {
                return
            }

            do {
                try strong_self.socket.sendto(data, address: address)
            }
            catch let error {
                writeHandler(.Failure(error))
            }
            writeHandler(.Success())
        }
    }

    public static func send(data: DispatchData <Void>, address: Address, queue: dispatch_queue_t, writeHandler: Result <Void> -> Void) {
        let socket = try! Socket(domain: address.family.rawValue, type: SOCK_DGRAM, protocol: IPPROTO_UDP)
        dispatch_async(queue) {
            do {
                try socket.sendto(data, address: address)
            }
            catch let error {
                writeHandler(.Failure(error))
            }
            writeHandler(.Success())
        }
    }
}

// MARK: -

extension UDPChannel: CustomStringConvertible {
    public var description: String {
        return "\(self.dynamicType)(\"\(label ?? "")\")"
    }
}

// MARK: -

private extension UDPChannel {

    func read() throws {

        let data: NSMutableData! = NSMutableData(length: 4096)

        var addressData = Array <Int8> (count: Int(SOCK_MAXADDRLEN), repeatedValue: 0)
        let (result, address) = addressData.withUnsafeMutableBufferPointer() {
            (inout ptr: UnsafeMutableBufferPointer <Int8>) -> (Int, Address?) in
            var addrlen: socklen_t = socklen_t(SOCK_MAXADDRLEN)
            let result = Darwin.recvfrom(socket.descriptor, data.mutableBytes, data.length, 0, UnsafeMutablePointer<sockaddr> (ptr.baseAddress), &addrlen)
            guard result >= 0 else {
                return (result, nil)
            }
            let addr = UnsafeMutablePointer<sockaddr> (ptr.baseAddress)
            let address = Address(addr: addr)
            return (result, address)
        }

        guard result >= 0 else {
            let error = Error.Generic("recvfrom() failed")
            errorHandler?(error)
            throw error
        }

        data.length = result
        let datagram = Datagram(from: address!, timestamp: Timestamp(), data: DispatchData <Void> (buffer: data.toUnsafeBufferPointer()))
        readHandler?(datagram)
    }

    func cleanup() {
        defer {
            socket = nil
            source = nil
        }

        do {
            try socket.close()
        }
        catch let error {
            errorHandler?(error)
        }
    }
}

// MARK: -

public extension UDPChannel {
    public func send(data: NSData, address: Address? = nil, writeHandler: Result <Void> -> Void) {
        let data = DispatchData <Void> (start: data.bytes, count: data.length)
        send(data, address: address ?? self.address, writeHandler: writeHandler)
    }
}

// Private for now - make public soon?
private extension Socket {
    func sendto(data: DispatchData <Void>, address: Address) throws {
        let result = address.with() {
            address in
            return data.createMap() {
                (_, buffer) in
                return Darwin.sendto(descriptor, buffer.baseAddress, buffer.count, 0, address, socklen_t(address.memory.sa_len))
            }
        }
        // TODO: what about "partial" sends.
        if result < data.length {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }
}
