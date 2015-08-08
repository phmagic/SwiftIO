//
//  Address.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

// TODO; Make equatable and comparable and hashable

/**
 *  A wrapper for a POSIX sockaddr structure.
 *
 *  sockaddr generally store IP address (either IPv4 or IPv6), port, protocol family and type.
 */
public enum Address {
    case INET(in_addr)
    case INET6(in6_addr)

    init(addr:in_addr) {
        self = .INET(addr)
    }

    init(addr:in6_addr) {
        self = .INET6(addr)
    }

    var addressFamily:Int32 {
        switch self {
            case .INET:
                return AF_INET
            case .INET6:
                return AF_INET6
        }
    }
}

//extension Address: Equatable {
//}
//
//public func ==(lhs: Address, rhs: Address) -> Bool {
//
//    switch (lhs, rhs) {
//        case .INET, .INET:
//            break
//        case .INET6, .INET6:
//            break
//        default:
//            return false
//    }
//}

// MARK: -

extension Address {
    public func withUnsafePointer <Result> (@noescape body: UnsafePointer<Void> -> Result) -> Result {
        switch self {
            case .INET(var addr):
                return Swift.withUnsafePointer(&addr) {
                    let ptr = UnsafePointer <Void> ($0)
                    return body(ptr)
                }
            case .INET6(var addr):
                return Swift.withUnsafePointer(&addr) {
                    let ptr = UnsafePointer <Void> ($0)
                    return body(ptr)
                }
        }
    }
}

extension Address {
    public var address:String {
        return withUnsafePointer() {
            (inputPtr:UnsafePointer<Void>) -> String in
            var buffer = Array <Int8> (count: Int(INET6_ADDRSTRLEN) + 1, repeatedValue: 0)
            return buffer.withUnsafeMutableBufferPointer() {
                (inout outputBuffer:UnsafeMutableBufferPointer <Int8>) -> String in
                let result = inet_ntop(self.addressFamily, inputPtr, outputBuffer.baseAddress, socklen_t(INET6_ADDRSTRLEN))
                return String(CString: result, encoding: NSASCIIStringEncoding)!
            }

        }
    }
}

extension Address: CustomStringConvertible {
    public var description: String {
        return address
    }
}

// MARK: -

public extension Address {

    static func addresses(hostname:String, `protocol`:InetProtocol = .TCP, family:ProtocolFamily? = nil) throws -> [Address] {
        var addresses:[Address] = []

        var hints = addrinfo()
        hints.ai_flags = AI_CANONNAME | AI_V4MAPPED
        hints.ai_protocol = `protocol`.rawValue
        if let family = family {
            hints.ai_family = family.rawValue
        }

        try getaddrinfo(hostname, service: "", hints: hints) {
            let addr = $0.memory.ai_addr.memory
            let address = try! Address(addr:addr)
            addresses.append(address)
            return true
        }

        return addresses
    }

    init(addr:sockaddr) throws {
        switch Int32(addr.sa_family) {
            case AF_INET:
                let sockaddr = addr.to_sockaddr_in()
                self = .INET(sockaddr.sin_addr)
            case AF_INET6:
                let sockaddr = addr.to_sockaddr_in6()
                self = .INET6(sockaddr.sin6_addr)
            default:
                throw Error.generic("Invalid sockaddr family")
        }
    }

    func to_sockaddr(port port:UInt16) -> sockaddr {
        switch self {
            case .INET(let addr):
                return sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: in_port_t(port.bigEndian), sin_addr: addr).to_sockaddr()
            default:
                fatalError()
        }
        fatalError()
    }

    init(address:String, family:ProtocolFamily? = nil) throws {
        self = try Address.addresses(address, family: family).first!
    }
}

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

extension sockaddr_in: CustomStringConvertible {
    public var description: String {
        let address = Address(addr: sin_addr)
        return "\(address):\(sin_port)"
    }
}