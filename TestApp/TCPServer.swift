//
//  Server.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftIO
import SwiftUtilities

public class TCPServer {

    public let addresses: [Address]

    public var clientShouldConnect: (Address -> Bool)?
    public var clientWillConnect: (TCPChannel -> Void)?
    public var clientDidConnect: (TCPChannel -> Void)?
    public var clientDidDisconnect: (TCPChannel -> Void)?

    public var errorDidOccur: (ErrorType -> Void)? = {
        (error) in
        log?.debug("Server got: \(error)")
    }

    private var listenersByAddress: [Address: TCPListener] = [:]
    private let queue = dispatch_queue_create("io.schwa.TCPServer", DISPATCH_QUEUE_SERIAL)
    private var connections = SafeSet <TCPChannel> ()

    public init(address: Address) throws {
        self.addresses = [address]
    }

    public func startListening() throws {
        for address in addresses {
            print("startListening on \(address)")
            try startListening(address)
        }
    }


    private func startListening(address: Address) throws {

        let listener = try TCPListener(address: address, queue: queue)

        listener.clientShouldConnect = clientShouldConnect
        listener.clientWillConnect = {
            [weak self] channel in

            guard let strong_self = self else {
                return
            }

            channel.state.addObserver(strong_self, queue: dispatch_get_main_queue()) {
                (old, new) in

                guard let strong_self = self else {
                    return
                }
                if new == .Unconnected {
                    strong_self.connections.remove(channel)
                    strong_self.clientDidDisconnect?(channel)
                }
            }
            strong_self.clientWillConnect?(channel)
        }
        listener.clientDidConnect = {
            [weak self] channel in

            guard let strong_self = self else {
                return
            }

            strong_self.connections.insert(channel)
            strong_self.clientDidConnect?(channel)
        }
        listener.errorDidOccur = errorDidOccur

        try listener.startListening()

        listenersByAddress[address] = listener
    }

    public func stopListening() throws {

        for (address, listener) in listenersByAddress {
            try listener.stopListening()
            listenersByAddress[address] = nil
        }

    }

    public func disconnectAllClients() throws {
        for connection in connections {
            connection.disconnect() {
                (result) in
                log?.debug("Server disconnect all: \(result)")
            }
        }
    }
}

// MARK: -

public class TCPListener {

    public let address: Address
    public let queue: dispatch_queue_t
    public private(set) var listeningSocket: Socket?
    public var listening: Bool {
        return listeningSocket != nil
    }

    public var clientShouldConnect: (Address -> Bool)?
    public var clientWillConnect: (TCPChannel -> Void)?
    public var clientDidConnect: (TCPChannel -> Void)?
    public var errorDidOccur: (ErrorType -> Void)? = {
        (error) in
        log?.debug("Server got: \(error)")
    }

    private var source: dispatch_source_t!

    public init(address: Address, queue: dispatch_queue_t? = nil) throws {
        self.address = address
        self.queue = queue ?? dispatch_queue_create("io.schwa.TCPListener", DISPATCH_QUEUE_SERIAL)
    }

    public func startListening() throws {

        listeningSocket = try Socket(domain: address.family.rawValue, type: SOCK_STREAM, `protocol`: IPPROTO_TCP)

        guard let listeningSocket = listeningSocket else {
            throw Error.Generic("Socket() failed")
        }

        listeningSocket.socketOptions.reuseAddress = true

        try listeningSocket.bind(address)
        try listeningSocket.setNonBlocking(true)
        try listeningSocket.listen()

        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(listeningSocket.descriptor), 0, queue)
        dispatch_source_set_event_handler(source) {
            [weak self] in

            self?.accept()
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

    private func accept() {
        do {
            guard let listeningSocket = listeningSocket else {
                throw Error.Generic("Socket() failed")
            }
            let (socket, address) = try listeningSocket.accept()

            if let clientShouldConnect = clientShouldConnect where clientShouldConnect(address) == false {
                return
            }

            let channel = try TCPChannel(address: address, socket: socket) {
                (channel) in

                clientWillConnect?(channel)
            }
            clientDidConnect?(channel)
        }
        catch let error {
            errorDidOccur?(error)
        }

    }

}
