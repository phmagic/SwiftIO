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
        try connect(address, timeout: 30)
    }
    
    func connect(address: Address, timeout: Int) throws {
        // Set the socket to be non-blocking
        try setNonBlocking(true)
        
        var addr = sockaddr_storage(address: address)
        try withUnsafePointer(&addr) {
            addrPtr in
            
            // put descriptor in write set for monitoring set
            var writeFileDescriptors = fd_set()
            fdZero(&writeFileDescriptors)
            fdSet(descriptor, &writeFileDescriptors)
            
            // This connect call should error out with code EINPROGRESS, if any other error occurs, throw it
            var ret = Darwin.connect(descriptor, UnsafePointer<sockaddr>(addrPtr), socklen_t(addr.ss_len))
            if ret == -1 && errno != EINPROGRESS {
                Darwin.close(descriptor)
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
            // If connect succeeded immediately
            if ret == 0 {
                return
            }
            
            // Check for writeability and block until either descriptor is writable or timed out
            var timeval = Darwin.timeval(tv_sec: timeout, tv_usec: 0)
            ret = select(descriptor + 1, nil, &writeFileDescriptors, nil, &timeval)
            // If the descriptor is not in the write set anymore, that means the select call has timed out, tear things down and throw timed out error
            if fdIsSet(descriptor, &writeFileDescriptors) == 0 {
                // Socket not writable
                Darwin.close(descriptor)
                throw Errno(rawValue: ETIMEDOUT) ?? Error.Unknown
            }
            
            switch ret {
            case -1:
                // Error occurred during select
                Darwin.close(descriptor)
                throw Errno(rawValue: errno) ?? Error.Unknown
                
            case 1:
                // select returned successfully with 1 descriptor
                // Now check error flags in socket options
                var so_error: Int32 = 0
                var len = socklen_t(sizeof(Int32))
                Darwin.getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &so_error, &len)
                
                // There is error
                if so_error != 0 {
                    Darwin.close(descriptor)
                    throw Errno(rawValue: so_error) ?? Error.Unknown
                }
                
            case 0:
                // Connection has timed out
                Darwin.close(descriptor)
                throw Errno(rawValue: ETIMEDOUT) ?? Error.Unknown
            default:
                break
            }



        }
    }

    func bind(address: Address) throws {
        var addr = sockaddr_storage(address: address)
        try withUnsafePointer(&addr) {
            ptr in
            let status = Darwin.bind(descriptor, UnsafePointer <sockaddr> (ptr), socklen_t(addr.ss_len))
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
        var addr = sockaddr_storage()
        return try withUnsafeMutablePointer(&addr) {
            ptr in

            var length = socklen_t(sizeof(sockaddr_storage))
            let socket = Darwin.accept(descriptor, UnsafeMutablePointer <sockaddr> (ptr), &length)
            if socket < 0 {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
            // TODO: Validate length
            let address = Address(sockaddr: addr)
            return (Socket(socket), address)
        }

    }

    func getAddress() throws -> Address {
        var addr = sockaddr_storage()
        return try withUnsafeMutablePointer(&addr) {
            ptr in

            var length = socklen_t(sizeof(sockaddr_storage))
            let status = getsockname(descriptor, UnsafeMutablePointer <sockaddr> (ptr), &length)
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
            return Address(sockaddr: addr)
        }
    }

    func getPeer() throws -> Address {
        var addr = sockaddr_storage()
        return try withUnsafeMutablePointer(&addr) {
            ptr in

            var length = socklen_t(sizeof(sockaddr_storage))
            let status = getpeername(descriptor, UnsafeMutablePointer <sockaddr> (ptr), &length)
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.Unknown
            }
            return Address(sockaddr: addr)
        }
    }
}
