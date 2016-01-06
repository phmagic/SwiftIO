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
    public private(set) var state: Atomic <State>

    // MARK: Callbacks

    public var readCallback: (Result <DispatchData <Void>> -> Void)? {
        willSet {
            preconditionConnected()
        }
    }

    /// Return true from shouldReconnect to initiate a reconnect. Does not make sense on a server socket.
    public var shouldReconnect: (Void -> Bool)? {
        willSet {
            preconditionConnected()
        }
    }
    public var stateChanged: ((State, State) -> Void)? {
        willSet {
            preconditionConnected()
        }
    }
    public var reconnectionDelay: NSTimeInterval = 5.0 {
        willSet {
            preconditionConnected()
        }
    }

    // MARK: Private properties

    private let queue: dispatch_queue_t
    private let lock = NSRecursiveLock()
    private var socket: Socket!
    private var channel: dispatch_io_t!
    private var disconnectCallback: (Result <Void> -> Void)?

    // MARK: Initialization

    public init(address: Address, port: UInt16, qos: qos_class_t = QOS_CLASS_DEFAULT) throws {
        self.address = address
        self.port = port
        let queueAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, 0)
        self.queue = dispatch_queue_create("io.schwa.SwiftIO.TCP.queue", queueAttribute)
        self.state = Atomic(State.Unconnected, lock: self.lock)
        self.state.valueChanged = {
            [weak self] (old, new) in
            self?.stateChanged?(old, new)
        }
    }

    public func connect(callback: Result <Void> -> Void) {

        dispatch_async(queue) {
            [weak self, address, port] in

            guard let strong_self = self else {
                return
            }

            if strong_self.state.value != .Unconnected {
                callback(.Failure(Error.Generic("Cannot connect channel in state \(strong_self.state.value)")))
                return
            }

            do {
                strong_self.state.value = .Connecting
                let socket = try Socket.TCP()
                try socket.connect(address, port: port)
                strong_self.socket = socket
                strong_self.state.value = .Connected
                try strong_self.createStream()
                callback(.Success())
            }
            catch let error {
                strong_self.state.value = .Unconnected
                callback(.Failure(error))
            }
        }
    }

    public func disconnect(callback: Result <Void> -> Void) {
        dispatch_async(queue) {
            [weak self] in

            guard let strong_self = self else {
                return
            }

            if strong_self.state.value == .Unconnected {
                callback(.Failure(Error.Generic("Cannot disconnect channel in state \(strong_self.state.value)")))
                return
            }

            strong_self.state.value = .Disconnecting
            strong_self.disconnectCallback = callback
            dispatch_io_close(strong_self.channel, DISPATCH_IO_STOP)
        }
    }

    // MARK: -

    public func write(data: DispatchData <Void>, callback: Result <Void> -> Void) {
        dispatch_io_write(channel, 0, data.data, queue) {
            (done, data, error) in

            guard error == 0 else {
                callback(Result.Failure(Errno(rawValue: error)!))
                return
            }
            callback(Result.Success())
        }
    }

    private func createStream() throws {
        channel = dispatch_io_create(DISPATCH_IO_STREAM, socket.descriptor, queue) {
            [weak self] (error) in

            guard let strong_self = self else {
                return
            }
            tryElseFatalError() {
                try strong_self.handleDisconnect()
            }
        }
        assert(channel != nil)
        dispatch_io_set_low_water(channel, 0)

        precondition(state.value == .Connected)

        dispatch_io_read(channel, 0, -1 /* Int(truncatingBitPattern:SIZE_MAX) */, queue) {
            [weak self] (done, data, error) in
            guard let strong_self = self else {
                return
            }
            guard error == 0 else {
                if error == ECONNRESET {
                    tryElseFatalError() {
                        try strong_self.handleDisconnect()
                    }
                    return
                }
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

    private func handleDisconnect() throws {
        let remoteDisconnect = (state.value != .Disconnecting)

        try socket.close()

        state.value = .Unconnected

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

    private func preconditionConnected() {
        precondition(state.value == .Unconnected, "Cannot change parameter while socket connected")
    }
}

// MARK: -

extension TCPChannel {

    public convenience init(hostname: String, port: UInt16, family: ProtocolFamily? = nil, qos: qos_class_t = QOS_CLASS_DEFAULT) throws {
        let addresses: [Address] = try Address.addresses(hostname, `protocol`: .TCP, family: family)
        try self.init(address: addresses.first!, port: port)
    }

    /// Create a TCPChannel from a pre-existing socket. The setup closure is called after the channel is created but before the state has changed to `Connecting`. This gives consumers a chance to configure the channel before it is fully connected.
    public convenience init(address: Address, port: UInt16, socket: Socket, qos: qos_class_t = QOS_CLASS_DEFAULT, setup: (TCPChannel -> Void)? = nil) throws {
        try self.init(address: address, port: port)
        self.socket = socket
        setup?(self)
        state.value = .Connected
        try createStream()
    }

}


