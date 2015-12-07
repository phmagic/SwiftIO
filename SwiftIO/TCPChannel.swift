//
//  TCPChannel.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/23/15.
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

import SwiftUtilities

public class TCPChannel {

    public enum State {
        case Unconnected
        case Connecting
        case Connected
        case Disconnecting
    }

    public let address: Address
    public let port: UInt16
    public var qos = QOS_CLASS_DEFAULT {
        willSet {
            precondition(state == .Unconnected, "Cannot change parameter while socket connected")
        }
    }
    public var readCallback: (Result <DispatchData <Void>> -> Void)? {
        willSet {
            precondition(state == .Unconnected, "Cannot change parameter while socket connected")
        }
    }

    /// Return true from shouldReconnect to initiate a reconnect.
    public var shouldReconnect: (Void -> Bool)? {
        willSet {
            precondition(state == .Unconnected, "Cannot change parameter while socket connected")
        }
    }

    public var stateChangeCallback: ((State, State) -> Void)? {
        willSet {
            precondition(state == .Unconnected, "Cannot change parameter while socket connected")
        }
    }

    public var reconnectionDelay: NSTimeInterval = 5.0 {
        willSet {
            precondition(state == .Unconnected, "Cannot change parameter while socket connected")
        }
    }

    public private(set) var queue: dispatch_queue_t!
    public private(set) var socketDescriptor: Int32!
    public private(set) var channel: dispatch_io_t!
    public private(set) var state: State = .Unconnected {
        didSet {
            stateChangeCallback?(oldValue, state)
        }
    }
    private var disconnectCallback: (Result <Void> -> Void)?


    public init(address: Address, port: UInt16) throws {
        self.address = address
        self.port = port
    }

    public convenience init(hostname: String, port: UInt16, family: ProtocolFamily? = nil) throws {
        let addresses: [Address] = try Address.addresses(hostname, `protocol`: .TCP, family: family)
        try self.init(address: addresses.first!, port: port)
    }

    public func connect(callback: Result <Void> -> Void) {

        precondition(state == .Unconnected)

        let queueAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, 0)
        queue = dispatch_queue_create("io.schwa.SwiftIO.UDP.receiveQueue", queueAttribute)
        precondition(queue != nil, "Could not create dispatch queue")

        dispatch_async(queue) {
            [weak self, address, port, queue] in

            guard let strong_self = self else {
                return
            }

            strong_self.state = .Connecting

            let socketDescriptor = Darwin.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
            guard socketDescriptor >= 0 else {
                let error = Errno(rawValue: errno)!
                close(socketDescriptor)
                callback(Result.Failure(error))
                return
            }

            var addr = address.to_sockaddr(port: port)

            let result = Darwin.connect(socketDescriptor, &addr, socklen_t(sizeof(sockaddr)))
            guard result == 0 else {
                let error = Errno(rawValue: errno)!
                close(socketDescriptor)
                strong_self.state = .Unconnected
                callback(Result.Failure(error))
                return
            }

            let channel = dispatch_io_create(DISPATCH_IO_STREAM, socketDescriptor, queue) {
                (error) in

                guard let strong_self = self else {
                    return
                }

                strong_self.handleDisconnect()
            }

            dispatch_io_set_low_water(channel, 0)

            strong_self.state = .Connected
            strong_self.channel = channel
            strong_self.socketDescriptor = socketDescriptor

            strong_self.startReading()

            callback(Result.Success())
        }
    }

    public func disconnect(callback: Result <Void> -> Void) {
        dispatch_async(queue) {
            [weak self] in
            guard let strong_self = self else {
                return
            }
            precondition(strong_self.state == .Connected)
            strong_self.state = .Disconnecting
            strong_self.disconnectCallback = callback
            dispatch_io_close(strong_self.channel, DISPATCH_IO_STOP)
        }
    }

    // MARK: -

    public func write(data: DispatchData <Void>, callback: Result <Void> -> Void) {

        precondition(state == .Connected)

        dispatch_io_write(channel, 0, data.data, queue) {
            (done, data, error) in

//            print("WRITE: \(done) \(data) \(error)")
            // TODO: Handle done

            guard error == 0 else {
                callback(Result.Failure(Errno(rawValue: error)!))
                return
            }

            callback(Result.Success())
        }
    }


    /// Callback might be called 0 or more times.
    private func startReading() {

        precondition(state == .Connected)

        assert(channel != nil)
        assert(queue != nil)

        dispatch_io_read(channel, 0, -1 /* Int(truncatingBitPattern:SIZE_MAX) */, queue) {
            [weak self] (done, data, error) in

//            print("READ \(done) \(data) \(error)")

            guard let strong_self = self else {
                // TODO
                return
            }

            guard error == 0 else {
                strong_self.readCallback?(Result.Failure(Errno(rawValue: error)!))
                return
            }

            switch (done, dispatch_data_get_size(data) > 0) {
                case (false, _), (true, true):
                    let dispatchData = DispatchData <Void> (data: data)
                    strong_self.readCallback?(Result.Success(dispatchData))
                case (true, false):
                    dispatch_io_close(strong_self.channel, dispatch_io_close_flags_t())
            }
        }
    }

    // MARK: -

    private func handleDisconnect() {
        let remoteDisconnect = (state != .Disconnecting)

        close(socketDescriptor)

        state = .Unconnected

        if let shouldReconnect = shouldReconnect where remoteDisconnect == true{
            let reconnectFlag = shouldReconnect()
            if reconnectFlag == true {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(reconnectionDelay * 1000000000))
                dispatch_after(time, queue) {
                    self.connect() {
                        [weak self] (result) in

                        guard let strong_self = self else {
                            return
                        }

                        if result.isFailure {
                            strong_self.shouldReconnect?()
                            strong_self.disconnectCallback?(result)
                            strong_self.disconnectCallback = nil
                        }
                    }
                }
                return
            }
        }

        shouldReconnect?()
        disconnectCallback?(Result.Success())
        disconnectCallback = nil
    }
}
