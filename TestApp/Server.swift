//
//  Server.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftIO
import SwiftUtilities

public class Server {

    public let address: Address
    public let port: UInt16

    public var clientShouldConnect: ((Address, UInt16) -> Bool)?
    public var clientWillConnect: (TCPChannel -> Void)?
    public var clientDidConnect: (TCPChannel -> Void)?
    public var clientDidDisconnect: (TCPChannel -> Void)?

    public var errorHandler: (ErrorType -> Void)? = {
        (error) in
        log?.debug("Server got: \(error)")
    }

    public private(set) var listeningSocket: Socket?
    public var listening: Bool {
        return listeningSocket != nil
    }

    private var source: dispatch_source_t?
    private let queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL)
    private var connections = SafeSet <TCPChannel> ()

    public init(address: Address, port: UInt16) throws {
        self.address = address
        self.port = port
    }

    public func startListening() throws {
        listeningSocket = try Socket.TCP()
        guard let listeningSocket = listeningSocket else {
            throw Error.Generic("Socket() failed")
        }
        listeningSocket.reuse = true
        try listeningSocket.bind(address, port: port)
        listeningSocket.nonBlocking = true
        try listeningSocket.listen()

        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(listeningSocket.descriptor), 0, queue)
        guard let source = source else {
            throw Error.Generic("dispatch_source_create() failed")
        }
        dispatch_source_set_event_handler(source) {
            [weak self] in

            guard let strong_self = self else {
                return
            }

            do {
                try strong_self.accept()
            }
            catch let error {
                strong_self.errorHandler?(error)
            }
        }
        dispatch_resume(source)
    }

    public func stopListening() throws {
        if let source = source {
            dispatch_source_cancel(source)
            self.source = nil
        }
        listeningSocket = nil
    }

    public func disconnectAllClients() throws {
        for connection in connections {
            connection.disconnect() {
                (result) in
                log?.debug("Server disconnect all: \(result)")
            }
        }
    }

    // MARK: -

    private func accept() throws {
        guard let listeningSocket = listeningSocket else {
            throw Error.Generic("Socket() failed")
        }
        let (socket, address, port) = try listeningSocket.accept()

        if let clientShouldConnect = clientShouldConnect where clientShouldConnect(address, port) == false {
            return
        }

        let channel = try TCPChannel(address: address, port: port, socket: socket) {
            (channel) in

            self.clientWillConnect?(channel)

            let oldStateChangeCallback = channel.stateChanged
            channel.stateChanged = {
                [weak self] (old, new) in

                guard let strong_self = self else {
                    return
                }

                if new == .Unconnected {
                    strong_self.connections.remove(channel)
                    strong_self.clientDidDisconnect?(channel)
                }

                oldStateChangeCallback?(old, new)
            }

        }

        connections.insert(channel)
        clientDidConnect?(channel)
    }
}

// MARK: -
