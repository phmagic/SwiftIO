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

}

// MARK: Socket options

extension Socket {

    public typealias SocketType = Int32

    public var type: SocketType {
        get {
            return socketOptions.type
        }
    }

    public func setNonBlocking(nonBlocking: Bool) throws {
        SwiftIO.setNonblocking(descriptor, nonBlocking)
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

    func connect(address: Address) throws {
        try address.with() {
            addr in
            let status = Darwin.connect(descriptor, addr, socklen_t(addr.memory.sa_len))
            guard status == 0 else {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
        }
    }

    func bind(address: Address) throws {
        try address.with() {
            addr in
            let status = Darwin.bind(descriptor, addr, socklen_t(addr.memory.sa_len))
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
        }
    }

    func listen(backlog: Int = 1) throws {
        precondition(type == SOCK_STREAM, "\(#function) should only be used on `SOCK_STREAM` sockets")

        let status = Darwin.listen(descriptor, Int32(backlog))
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }

    func accept() throws -> (Socket, Address) {
        precondition(type == SOCK_STREAM, "\(#function) should only be used on `SOCK_STREAM` sockets")

        return try sockaddr.with() {
            sockaddr, length in

            var length = length
            let socket = Darwin.accept(descriptor, sockaddr, &length)
            if socket < 0 {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
            let address = Address(addr: sockaddr)
            return (Socket(socket), address)
        }
    }

    func getAddress() throws -> Address {
        return try sockaddr.with() {
            sockaddr, length in

            var length = length
            let status = getsockname(descriptor, sockaddr, &length)
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
            return Address(addr: sockaddr)
        }
    }

    func getPeer() throws -> Address {
        return try sockaddr.with() {
            sockaddr, length in

            var length = length
            let status = getpeername(descriptor, sockaddr, &length)
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
            return Address(addr: sockaddr)
        }
    }
}

// MARK: -

extension sockaddr {

    /**
     Create a temporary buffer big enough to hold the largest `sockaddr` possible (SOCK_MAXADDRLEN).

     Effectively a `sockaddr` flavoured convenience wrapper around Array.withUnsafeMutableBufferPointer
     */
    static func with <R> (@noescape closure: (UnsafeMutablePointer<sockaddr>, length: socklen_t) throws -> R) rethrows -> R {
        var buffer = Array <UInt8> (count: Int(SOCK_MAXADDRLEN), repeatedValue: 0)
        return try buffer.withUnsafeMutableBufferPointer() {
            (inout buffer: UnsafeMutableBufferPointer<UInt8>) -> R in
            let pointer = UnsafeMutablePointer <sockaddr> (buffer.baseAddress)
            return try closure(pointer, length: socklen_t(SOCK_MAXADDRLEN))
        }
    }

}
