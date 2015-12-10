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

    public var listeningSocket: Socket?
    public var listening: Bool {
        return listeningSocket != nil
    }

    private var source: dispatch_source_t?
    private let queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL)

    private var connections = SafeSet <TCPChannel> ()

    public var clientShouldConnect: (TCPChannel -> Bool)?
    public var clientWillConnect: (TCPChannel -> Void)?
    public var clientDidConnect: (TCPChannel -> Void)?
    public var errorHandler: (ErrorType -> Void)? = {
        (error) in
        print(error)
    }

    public init(address: Address, port: UInt16) throws {

        self.address = address
        self.port = port
    }

    public func start() throws {
        listeningSocket = try Socket.TCP()
        guard let listeningSocket = listeningSocket else {
            throw Error.Generic("Socket() failed")
        }
        listeningSocket.reuse = true
        try listeningSocket.bind(address, port: port)
        try listeningSocket.listen()
        listeningSocket.nonBlocking = true

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

    public func stop() throws {
        if let source = source {
            dispatch_source_cancel(source)
            self.source = nil
        }
        listeningSocket = nil
    }

    // MARK: -

    private func accept() throws {
        guard let listeningSocket = listeningSocket else {
            throw Error.Generic("Socket() failed")
        }
        let (socket, address, port) = try listeningSocket.accept()
        let channel = try TCPChannel(address: address, port: port, socket: socket)

        if let clientShouldConnect = clientShouldConnect where clientShouldConnect(channel) == false {
            return
        }
        clientWillConnect?(channel)

        let oldStateChangeCallback = channel.stateChangeCallback
        channel.stateChangeCallback = {
            (old, new) in
            if new == .Unconnected {
                self.connections.remove(channel)
            }

            oldStateChangeCallback?(old, new)
        }

        channel.triggerConnection() // TODO: This is BAD
        connections.insert(channel)
        clientDidConnect?(channel)
    }
}




class SafeSet <Element: AnyObject> {

    var set = NSMutableSet()
    var lock = NSLock()

    func insert(value: Element) {
        lock.with() {
            set.addObject(value)
        }
    }

    func remove(value: Element) {
        lock.with() {
            set.removeObject(value)
        }
    }


}



