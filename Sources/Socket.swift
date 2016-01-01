//
//  Socket.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Darwin

import SwiftUtilities

public class Socket {
    
    public typealias SocketType = Int32
    
    public private(set) var descriptor: Int32

    public init(_ descriptor: Int32) {
        self.descriptor = descriptor
    }

    deinit {
        if descriptor >= 0 {
            tryElseFatalError() {
                try close()
            }
        }
    }

    func close() throws {
        Darwin.close(descriptor)
        descriptor = -1
    }

    public var type: SocketType {
        get {
            var socketType: Int32 = 0
            var length = socklen_t(sizeof(Int32))
            
            getsockopt(descriptor, SOL_SOCKET, SO_TYPE, &socketType, &length)
            
            return socketType
        }
    }

    public var reuse: Bool {
        get {
            var reuseSocketFlag: Int = 1
            var length = socklen_t(sizeof(Int))
            getsockopt(descriptor, SOL_SOCKET, SO_REUSEADDR, &reuseSocketFlag, &length)
            return reuseSocketFlag != 0
        }
        set {
            var reuseSocketFlag: Int = newValue ? 1 : 0
            let status = setsockopt(descriptor, SOL_SOCKET, SO_REUSEADDR, &reuseSocketFlag, socklen_t(sizeof(Int)))
            if status != 0 {
                fatalError("Could not call setsockopt() on \(descriptor)")
            }
        }
    }

    public var nonBlocking: Bool {
        get {
            fatalError()
        }
        set {
            setNonblocking(descriptor, newValue)
        }
    }
}

// MARK: -

public extension Socket {

    convenience init(domain: Int32, type: Int32, `protocol`: Int32) throws {
        let descriptor = Darwin.socket(domain, type, `protocol`)
        if descriptor < 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
        self.init(descriptor)
    }

}

// MARK: -


public extension Socket {

    func connect(address: Address, port: UInt16) throws {
        var addr = address.to_sockaddr(port: port)
        let status = Darwin.connect(descriptor, &addr, socklen_t(sizeof(sockaddr)))
        guard status == 0 else {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }

    func bind(address: Address, port: UInt16) throws {
        var addr = address.to_sockaddr(port: port)
        let status = Darwin.bind(descriptor, &addr, socklen_t(addr.sa_len))
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }

    func listen(backlog: Int = 1) throws {
        precondition(type == SOCK_STREAM, "\(__FUNCTION__) should only be used on `SOCK_STREAM` sockets")
        
        let status = Darwin.listen(descriptor, Int32(backlog))
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }

    func accept() throws -> (Socket, Address, UInt16) {
        precondition(type == SOCK_STREAM, "\(__FUNCTION__) should only be used on `SOCK_STREAM` sockets")
        
        var incoming = sockaddr()
        var incomingSize = socklen_t(sizeof(sockaddr))
        let socket = Darwin.accept(descriptor, &incoming, &incomingSize)
        if socket < 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
        
        let (address, port) = try Address.fromSockaddr(incoming)
        return (Socket(socket), address, port)
    }

    func getPeer() throws -> (Address, UInt16) {
        var addr = sockaddr()
        var addrSize = socklen_t(sizeof(sockaddr))
        let status = getpeername(descriptor, &addr, &addrSize)
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
        return try Address.fromSockaddr(addr)
    }
}

// MARK: -

public extension Socket {

    static func TCP() throws -> Socket {
        return try Socket(domain: PF_INET, type: SOCK_STREAM, `protocol`: IPPROTO_TCP)
    }
    
    static func UDP() throws -> Socket {
        return try Socket(domain: PF_INET, type: SOCK_DGRAM, `protocol`: IPPROTO_UDP)
    }

}