//
//  Address.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
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

import SwiftUtilities
import Darwin
import Foundation

/**
 *  A wrapper for a POSIX sockaddr structure.
 *
 *  sockaddr generally store IP address (either IPv4 or IPv6), port, protocol family and type.
 */
public struct Address {

    enum InternalAddress {
        case INET(in_addr)
        case INET6(in6_addr)
    }

    let internalAddress: InternalAddress
    public let port: UInt16?

    public init(addr: in_addr, port: UInt16? = nil) {
        internalAddress = .INET(addr)
        self.port = port
    }

    public init(addr: in6_addr, port: UInt16? = nil) {
        internalAddress = .INET6(addr)
        self.port = port
    }

    var addressFamily: Int32 {
        switch internalAddress {
            case .INET:
                return AF_INET
            case .INET6:
                return AF_INET6
        }
    }

    var family: ProtocolFamily {
        return ProtocolFamily(rawValue: addressFamily)!
    }
}

extension Address: Equatable {
}

public func == (lhs: Address, rhs: Address) -> Bool {
    switch (lhs.internalAddress, rhs.internalAddress) {
        case (.INET(let lhs_addr), .INET(let rhs_addr)):
            return lhs_addr == rhs_addr && lhs.port == rhs.port
        case (.INET6(let lhs_addr), .INET6(let rhs_addr)):
            return lhs_addr == rhs_addr && lhs.port == rhs.port
        default:
            return false
    }
}

extension Address: Hashable {
    public var hashValue: Int {
        // TODO: cheating
        return description.hashValue
    }
}

extension Address: CustomStringConvertible {
    public var description: String {
        if let port = port {
            return "\(address):\(port)"
        }
        else {
            return address
        }
    }
}


extension Address: CustomDebugStringConvertible {
    public var debugDescription: String {

        return "Address(address: \"\(address)\", port: \((port != nil ? String(port!) : "nil")), family: \(family))"
    }
}

extension Address: CustomReflectable {
    public func customMirror() -> Mirror {
        return Mirror(self, children: [
            "family": String(addressFamily),
            "address": String(address),
            "port": port,
        ])
    }
}

// MARK: -

extension Address {
    public func withUnsafePointer <Result> (@noescape body: UnsafePointer<Void> throws -> Result) throws -> Result {
        switch internalAddress {
            case .INET(var addr):
                return try Swift.withUnsafePointer(&addr) {
                    let ptr = UnsafePointer <Void> ($0)
                    return try body(ptr)
                }
            case .INET6(var addr):
                return try Swift.withUnsafePointer(&addr) {
                    let ptr = UnsafePointer <Void> ($0)
                    return try body(ptr)
                }
        }
    }
}


// MARK: -

extension Address {
    public var address: String {
        return tryElseFatalError() {
            return try self.withUnsafePointer() {
                (inputPtr: UnsafePointer<Void>) -> String in
                return try inet_ntop(addressFamily: self.addressFamily, address: inputPtr)
            }
        }
    }
}

// MARK: sockaddr support

public extension Address {

    static func fromSockaddr(addr: sockaddr) throws -> Address {
        switch Int32(addr.sa_family) {
            case AF_INET:
                let addr = addr.to_sockaddr_in()
                let address = Address(addr: addr.sin_addr, port: addr.sin_port)
                return address
            case AF_INET6:
                let addr = addr.to_sockaddr_in6()
                let address = Address(addr: addr.sin6_addr, port: addr.sin6_port)
                return address
            default:
                throw Error.Generic("Invalid sockaddr family")
        }
    }

    init(addr: sockaddr, port: UInt16? = nil) throws {
        switch Int32(addr.sa_family) {
            case AF_INET:
                let sockaddr = addr.to_sockaddr_in()
                internalAddress = .INET(sockaddr.sin_addr)
            case AF_INET6:
                let sockaddr = addr.to_sockaddr_in6()
                internalAddress = .INET6(sockaddr.sin6_addr)
            default:
                throw Error.Generic("Invalid sockaddr family")
        }
        self.port = port
    }

    func to_sockaddr() -> sockaddr {
        guard let port = port else {
            fatalError("No port")
        }
        switch internalAddress {
            case .INET(let addr):
                return sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: in_port_t(port.networkEndian), sin_addr: addr).to_sockaddr()
            case .INET6(let addr):
                return sockaddr_in6(sin6_family: sa_family_t(AF_INET6), sin6_port: in_port_t(port.networkEndian), sin6_addr: addr).to_sockaddr()
        }
    }
}

// MARK: Hostname support

public extension Address {

    init(address: String, port: UInt16? = nil, `protocol`:InetProtocol? = nil, family: ProtocolFamily? = nil) throws {
        let addresses: [Address] = try Address.addresses(address, port: port, `protocol`: `protocol`, family: family)
        self = addresses.first!
    }

    static func addresses(hostname: String, port: UInt16? = nil, `protocol`:InetProtocol? = nil, family: ProtocolFamily? = nil) throws -> [(Address, InetProtocol, ProtocolFamily, String?)] {
        var results: [(Address, InetProtocol, ProtocolFamily, String?)] = []

        var hints = addrinfo()
//        hints.ai_flags |= AI_ADDRCONFIG // If the AI_ADDRCONFIG bit is set, IPv4 addresses shall be returned only if an IPv4 address is configured on the local system, and IPv6 addresses shall be returned only if an IPv6 address is con- figured on the local system.
        hints.ai_flags |= AI_CANONNAME
        hints.ai_flags |= AI_V4MAPPED // If the AI_V4MAPPED flag is specified along with an ai_family of AF_INET6, then getaddrinfo() shall return IPv4-mapped IPv6 addresses on finding no matching IPv6 addresses ( ai_addrlen shall be 16).  The AI_V4MAPPED flag shall be ignored unlessai_family equals AF_INET6.

        if let `protocol` = `protocol` {
            hints.ai_protocol = `protocol`.rawValue
        }
        if let family = family {
            hints.ai_family = family.rawValue
        }

        try getaddrinfo(hostname, service: "", hints: hints) {
            let addrinfo = $0.memory
            let addr = addrinfo.ai_addr.memory
            let address = try Address(addr: addr, port: port)
            precondition(socklen_t(addr.sa_len) == $0.memory.ai_addrlen)

            let family = ProtocolFamily(rawValue: addrinfo.ai_family)
            let `protocol` = InetProtocol(rawValue: addrinfo.ai_protocol)
            var canonicalName: String? = nil

            if addrinfo.ai_canonname != nil {
                canonicalName = String(CString: addrinfo.ai_canonname, encoding: NSASCIIStringEncoding)
            }

            let result = (address, `protocol`!, family!, canonicalName)
            results.append(result)


//    public var ai_family: Int32 /* PF_xxx */
//    public var ai_socktype: Int32 /* SOCK_xxx */
//    public var ai_protocol: Int32 /* 0 or IPPROTO_xxx for IPv4 and IPv6 */
//    public var ai_canonname: UnsafeMutablePointer<Int8> /* canonical name for hostname */


            return true
        }

        return results
    }


    static func addresses(hostname: String, port: UInt16? = nil, `protocol`:InetProtocol? = nil, family: ProtocolFamily? = nil) throws -> [Address] {
        var addresses: [Address] = []

        var hints = addrinfo()
//        hints.ai_flags |= AI_ADDRCONFIG // If the AI_ADDRCONFIG bit is set, IPv4 addresses shall be returned only if an IPv4 address is configured on the local system, and IPv6 addresses shall be returned only if an IPv6 address is con- figured on the local system.
//        hints.ai_flags |= AI_CANONNAME
        hints.ai_flags |= AI_V4MAPPED // If the AI_V4MAPPED flag is specified along with an ai_family of AF_INET6, then getaddrinfo() shall return IPv4-mapped IPv6 addresses on finding no matching IPv6 addresses ( ai_addrlen shall be 16).  The AI_V4MAPPED flag shall be ignored unlessai_family equals AF_INET6.

        if let `protocol` = `protocol` {
            hints.ai_protocol = `protocol`.rawValue
        }
        if let family = family {
            hints.ai_family = family.rawValue
        }

        try getaddrinfo(hostname, service: "", hints: hints) {
            let addr = $0.memory.ai_addr.memory
            precondition(socklen_t(addr.sa_len) == $0.memory.ai_addrlen)
            let address = try Address(addr: addr, port: port)
            addresses.append(address)

//    public var ai_family: Int32 /* PF_xxx */
//    public var ai_socktype: Int32 /* SOCK_xxx */
//    public var ai_protocol: Int32 /* 0 or IPPROTO_xxx for IPv4 and IPv6 */
//    public var ai_canonname: UnsafeMutablePointer<Int8> /* canonical name for hostname */

            return true
        }

        let addressSet = Set <Address> (addresses)

        return Array <Address> (addressSet)
    }
}

public extension Address {
    static func addressesForInterfaces() throws -> [String:Address] {
        let addressesForInterfaces = getAddressesForInterfaces() as! [String:NSData]
        let pairs: [(String, Address)] = try addressesForInterfaces.map() {
            (interface, addressData) in
            let sockAddr = UnsafePointer <sockaddr> (addressData.bytes)
            return (interface, try Address(addr: sockAddr.memory))
        }
        return Dictionary <String, Address> (pairs)
    }
}


private extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}
