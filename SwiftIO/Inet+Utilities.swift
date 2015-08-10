//
//  Inet+Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Darwin

import SwiftUtilities

// MARK: in_addr extensions

extension in_addr: Equatable {
}

public func ==(lhs: in_addr, rhs: in_addr) -> Bool {
    return bitwiseEquality(lhs, rhs)
}

extension in_addr: CustomStringConvertible {
    public var description: String {
        // TODO: replace with inet_ntop
        let buffer = inet_ntoa(self)
        return String(CString: buffer, encoding: NSASCIIStringEncoding)!
    }
}

// MARK: in6_addr extensions

extension in6_addr: Equatable {
}

public func ==(lhs: in6_addr, rhs: in6_addr) -> Bool {
    return bitwiseEquality(lhs, rhs)
}

// MARK: -

extension sockaddr {

    func to_sockaddr_in() -> sockaddr_in {
        assert(sa_family == sa_family_t(AF_INET))
        assert(Int(sa_len) == sizeof(sockaddr_in))
        var copy = self
        return withUnsafePointer(&copy) {
            (ptr:UnsafePointer <sockaddr>) -> sockaddr_in in
            let ptr = UnsafePointer <sockaddr_in> (ptr)
            return ptr.memory
        }
    }

    func to_sockaddr_in6() -> sockaddr_in6 {
        assert(sa_family == sa_family_t(AF_INET6))
        assert(Int(sa_len) == sizeof(sockaddr_in6))
        var copy = self
        return withUnsafePointer(&copy) {
            (ptr:UnsafePointer <sockaddr>) -> sockaddr_in6 in
            let ptr = UnsafePointer <sockaddr_in6> (ptr)
            return ptr.memory
        }
    }

    /// Still in network endian.
    var port:UInt16 {
        switch self.sa_family {
            case sa_family_t(AF_INET):
                let addr = to_sockaddr_in()
                return addr.sin_port
            case sa_family_t(AF_INET6):
                let addr = to_sockaddr_in6()
                return addr.sin6_port
            default:
                preconditionFailure()
        }
    }
}

// MARK: sockaddr_in extensions

extension sockaddr_in {

    init(sin_family: sa_family_t, sin_port: in_port_t, sin_addr: in_addr) {
        self.sin_len = __uint8_t(sizeof(sockaddr_in))
        self.sin_family = sin_family
        self.sin_port = sin_port
        self.sin_addr = sin_addr
        self.sin_zero = (Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0))
    }

    func to_sockaddr() -> sockaddr {
        var copy = self
        return withUnsafePointer(&copy) {
            (ptr:UnsafePointer <sockaddr_in>) -> sockaddr in
            let ptr = UnsafePointer <sockaddr> (ptr)
            return ptr.memory
        }
    }
}

// MARK: sockaddr_in6 extensions

extension sockaddr_in6 {

    init(sin6_family: sa_family_t, sin6_port: in_port_t, sin6_addr: in6_addr) {
        self.sin6_len = __uint8_t(sizeof(sockaddr_in6))
        self.sin6_family = sin6_family
        self.sin6_port = sin6_port
        self.sin6_flowinfo = 0
        self.sin6_addr = sin6_addr
        self.sin6_scope_id = 0
    }

    func to_sockaddr() -> sockaddr {
        var copy = self
        return withUnsafePointer(&copy) {
            (ptr:UnsafePointer <sockaddr_in6>) -> sockaddr in
            let ptr = UnsafePointer <sockaddr> (ptr)
            return ptr.memory
        }
    }
}

// MARK: Swift wrapper functions for useful (but fiddly) POSIX network functions

public func inet_ntop(addressFamily addressFamily:Int32, address:UnsafePointer <Void>) throws -> String {
    var buffer = Array <Int8> (count: Int(INET6_ADDRSTRLEN) + 1, repeatedValue: 0)
    return buffer.withUnsafeMutableBufferPointer() {
        (inout outputBuffer:UnsafeMutableBufferPointer <Int8>) -> String in
        let result = inet_ntop(addressFamily, address, outputBuffer.baseAddress, socklen_t(INET6_ADDRSTRLEN))
        return String(CString: result, encoding: NSASCIIStringEncoding)!
    }
}

// MARK: -

public func getnameinfo(addr:UnsafePointer<sockaddr>, addrlen:socklen_t, inout hostname:String?, inout service:String?, flags:Int32) throws {
    var hostnameBuffer = [Int8](count: Int(NI_MAXHOST), repeatedValue: 0)
    var serviceBuffer = [Int8](count: Int(NI_MAXSERV), repeatedValue: 0)
    let result = hostnameBuffer.withUnsafeMutableBufferPointer() {
        (inout hostnameBufferPtr:UnsafeMutableBufferPointer<Int8>) -> Int32 in
        serviceBuffer.withUnsafeMutableBufferPointer() {
            (inout serviceBufferPtr:UnsafeMutableBufferPointer<Int8>) -> Int32 in
            let result = getnameinfo(
                addr, addrlen,
                hostnameBufferPtr.baseAddress, socklen_t(NI_MAXHOST),
                serviceBufferPtr.baseAddress, socklen_t(NI_MAXSERV),
                flags)
            if result == 0 {
                hostname = String(CString: hostnameBufferPtr.baseAddress, encoding: NSASCIIStringEncoding)
                service = String(CString: serviceBufferPtr.baseAddress, encoding: NSASCIIStringEncoding)
            }
            return result
        }
    }
    guard result == 0 else {
        throw Error.posix(result, "getnameinfo() failed")
    }
}

// MARK: -

//public func getaddrinfo(hostname:String, service:String, hints:addrinfo) throws -> addrinfo {
//}

public func getaddrinfo(hostname:String, service:String, hints:addrinfo, info:UnsafeMutablePointer<UnsafeMutablePointer<addrinfo>>) throws {
    var hints = hints
    let result = hostname.withCString() {
        (hostnameBuffer:UnsafePointer <Int8>) -> Int32 in
        return service.withCString() {
            (serviceBuffer:UnsafePointer <Int8>) -> Int32 in
            return getaddrinfo(hostnameBuffer, serviceBuffer, &hints, info)
        }
    }
    guard result == 0 else {
        throw Error.posix(result, "getaddrinfo() failed")
    }
}

public func getaddrinfo(hostname:String, service:String, hints:addrinfo, block:UnsafePointer<addrinfo> -> Bool) throws {
    var hints = hints
    var info = UnsafeMutablePointer<addrinfo>()
    let result = hostname.withCString() {
        (hostnameBuffer:UnsafePointer <Int8>) -> Int32 in
        return service.withCString() {
            (serviceBuffer:UnsafePointer <Int8>) -> Int32 in
            return getaddrinfo(hostnameBuffer, serviceBuffer, &hints, &info)
        }
    }
    guard result == 0 else {
        throw Error.posix(result, "getaddrinfo() failed")
    }

    var current = info
    while current != nil {
        if block(current) == false {
            break
        }
        current = current.memory.ai_next
    }
    freeaddrinfo(info)
}
