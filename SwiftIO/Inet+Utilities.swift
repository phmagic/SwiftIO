//
//  Inet+Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Darwin

public extension UInt16 {
    init(networkEndian value:UInt16) {
        self = UInt16(bigEndian: value)
    }
    var networkEndian: UInt16 {
        return bigEndian
    }
}

public extension UInt32 {
    init(networkEndian value:UInt32) {
        self = UInt32(bigEndian: value)
    }
    var networkEndian: UInt32 {
        return bigEndian
    }
}

public extension UInt64 {
    init(networkEndian value:UInt64) {
        self = UInt64(bigEndian: value)
    }
    var networkEndian: UInt64 {
        return bigEndian
    }
}

public extension Int16 {
    init(networkEndian value:Int16) {
        self = Int16(bigEndian: value)
    }
    var networkEndian: Int16 {
        return bigEndian
    }
}

public extension Int32 {
    init(networkEndian value:Int32) {
        self = Int32(bigEndian: value)
    }
    var networkEndian: Int32 {
        return bigEndian
    }
}

public extension Int64 {
    init(networkEndian value:Int64) {
        self = Int64(bigEndian: value)
    }
    var networkEndian: Int64 {
        return bigEndian
    }
}

// MARK: -

public extension in_addr {
    init(string:String) throws {
        let (result, address) = string.withCString() {
            (f: UnsafePointer<Int8>) -> (Int32, in_addr) in
            var address = in_addr()
        // TODO: replace with inet_pton
        let result = inet_aton(f, &address)
        return (result, address)
        }
        if result == 0 {
            self = address
        }
        else {
            self = in_addr()
            throw Error.generic("inet_aton() failed")
        }
    }
}

extension in_addr: CustomStringConvertible {
    public var description: String {
        // TODO: replace with inet_ntop
        let buffer = inet_ntoa(self)
        return String(CString: buffer, encoding: NSASCIIStringEncoding)!
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




extension sockaddr {

    func to_sockaddr_in() -> sockaddr_in {
        assert(sa_family == sa_family_t(AF_INET))
        assert(Int(sa_len) == sizeof(sockaddr_in)) // TODO: this could be incorrect
        var copy = self
        return withUnsafePointer(&copy) {
            (ptr:UnsafePointer <sockaddr>) -> sockaddr_in in
            let ptr = UnsafePointer <sockaddr_in> (ptr)
            return ptr.memory
        }
    }

    func to_sockaddr_in6() -> sockaddr_in6 {
        assert(sa_family == sa_family_t(AF_INET6))
        assert(Int(sa_len) == sizeof(sockaddr_in6)) // TODO: this could be incorrect
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


