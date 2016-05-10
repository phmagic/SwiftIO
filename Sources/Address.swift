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

import Darwin

import SwiftUtilities

/**
 *  An internet address.
 *
 *  sockaddr generally stores IP address (either IPv4 or IPv6), port, protocol family and type.
 */
public struct Address {

    /// Enum representing the INET or INET6 address. Generally you can avoid this type.
    public enum InetAddress {
        case INET(in_addr)
        case INET6(in6_addr)
    }

    public let inetAddress: InetAddress

    /// Optional native endian port of the address
    public let port: UInt16?

    /**
     Note: You generally shouldn't need to use this. There are other init methods that might be more suitable.

     - parameter inetAddress: Enum representation of the address encapsulating either a in_addr (IPV4) or in6_addr (IPV6) structure.
     - parameter port: _native endian_ port number
     */
    public init(inetAddress: InetAddress, port: UInt16) {
        self.inetAddress = inetAddress
        self.port = port
    }

    /**
     Create a new Address with a different port but same inet address.

     - parameter port: _native endian_ port number
     */
    public func addressWithPort(port: UInt16) -> Address {
        return Address(inetAddress: inetAddress, port: port)
    }

}

// MARK: Equatable

extension Address: Equatable {
}

public func == (lhs: Address, rhs: Address) -> Bool {
    switch (lhs.inetAddress, rhs.inetAddress) {
        case (.INET(let lhs_addr), .INET(let rhs_addr)):
            return lhs_addr == rhs_addr && lhs.port == rhs.port
        case (.INET6(let lhs_addr), .INET6(let rhs_addr)):
            return lhs_addr == rhs_addr && lhs.port == rhs.port
        default:
            return false
    }
}

// MARK: Hashable

extension Address: Hashable {
    public var hashValue: Int {
        // TODO: cheating
        return description.hashValue
    }
}

// MARK: Comparable

extension Address: Comparable {
}

public func < (lhs: Address, rhs: Address) -> Bool {

    let lhsPort = lhs.port.map({ Int32($0) }) ?? -1
    let rhsPort = rhs.port.map({ Int32($0) }) ?? -1

    let comparisons = [
        compare(lhs.family.rawValue, rhs.family.rawValue),
        compare(lhs.address, rhs.address),
        compare(lhsPort, rhsPort),
    ]
    for comparison in comparisons {
        switch comparison {
            case .Lesser:
                return true
            case .Greater:
                return false
            default:
                break
        }
    }
    return false
}

// MARK: CustomStringConvertible

extension Address: CustomStringConvertible {
    public var description: String {
        if let port = port {
            switch family {
                case .INET:
                    return "\(address):\(port)"
                case .INET6:
                    return "[\(address)]:\(port)"
            }
        }
        else {
            switch family {
                case .INET:
                    return address
                case .INET6:
                    return "[\(address)]"
            }
        }
    }
}

// MARK: -

extension Address {

    // TODO: Rename to "name"

    /// A string representation of the Address _without_ the port
    public var address: String {
        return tryElseFatalError() {
            switch inetAddress {
                case .INET(var addr):
                    return try inet_ntop(addressFamily: self.family.rawValue, address: &addr)
                case .INET6(var addr):
                    return try inet_ntop(addressFamily: self.family.rawValue, address: &addr)
            }
        }
    }
}

// MARK: -

extension Address {

    /**
     Create an address from a POSIX in_addr (IPV4) structure and optional port

     - parameter addr: in_addr representation of address
     - parameter port: _native endian_ port number
     */
    public init(addr: in_addr, port: UInt16? = nil) {
        inetAddress = .INET(addr)
        self.port = port
    }

    /**
     Create an address from a (host endian) UInt32 representation. Example ```Address(0x7f000001)```

     - parameter addr: 32-bit _native endian_ integer representation of the address.
     - parameter port: _native endian_ port number
     */
    public init(addr: UInt32, port: UInt16? = nil) {
        let addr = in_addr(s_addr: addr.networkEndian)
        inetAddress = .INET(addr)
        self.port = port
    }

    /**
     Create an address from a POSIX in6_addr (IPV46) structure and optional port

     - parameter addr: in6_addr representation of address
     - parameter port: _native endian_ port number
     */
    public init(addr: in6_addr, port: UInt16? = nil) {
        inetAddress = .INET6(addr)
        self.port = port
    }

    public func to_in_addr() -> in_addr? {
        switch inetAddress {
            case .INET(let addr):
                return addr
            default:
                return nil
        }
    }

    public func to_in6_addr() -> in6_addr? {
        switch inetAddress {
            case .INET6(let addr):
                return addr
            default:
                return nil
        }
    }

    public var family: ProtocolFamily {
        switch inetAddress {
            case .INET:
                return ProtocolFamily(rawValue: AF_INET)!
            case .INET6:
                return ProtocolFamily(rawValue: AF_INET6)!
        }
    }
}

public extension Address {
    init(sockaddr: sockaddr_storage) {
        switch Int32(sockaddr.ss_family) {
            case AF_INET:
                var src = sockaddr
                var dst = sockaddr_in()
                unsafeCopy(destination: &dst, source: &src)
                inetAddress = .INET(dst.sin_addr)
                port = dst.sin_port != 0 ? UInt16(networkEndian: dst.sin_port) : nil
            case AF_INET6:
                var src = sockaddr
                var dst = sockaddr_in6()
                unsafeCopy(destination: &dst, source: &src)
                inetAddress = .INET6(dst.sin6_addr)
                port = dst.sin6_port != 0 ? UInt16(networkEndian: dst.sin6_port) : nil
            default:
                fatalError("Invalid sockaddr family")
        }
    }
}

public extension sockaddr_storage {

    init(address: Address) {
        guard let port = address.port else {
            fatalError("No port")
        }
        switch address.inetAddress {
            case .INET(let addr):
                self = sockaddr_storage(addr: addr, port: port)
            case .INET6(let addr):
                self = sockaddr_storage(addr: addr, port: port)
        }
    }

}

// MARK: Hostname support

public extension Address {

    static func addresses(hostname: String, `protocol`:InetProtocol? = nil, family: ProtocolFamily? = ProtocolFamily.preferred) throws -> [Address] {
        var hints = addrinfo()
        if let `protocol` = `protocol` {
            hints.ai_protocol = `protocol`.rawValue
        }
        if let family = family {
            hints.ai_family = family.rawValue
        }
        return try addresses(hostname, service: "", hints: hints)
    }

    static func addresses(hostname: String, service: String, hints: addrinfo) throws -> [Address] {
        return try getaddrinfo(hostname, service: service, hints: hints)
    }
}

public extension Address {

    /**
     Create an address from string.

     Examples:
        ```
        try Address("127.0.0.1")
        try Address("127.0.0.1:80")
        try Address("localhost")
        try Address("localhost:80")
        try Address("[::1]")
        try Address("[::1]:80")
        ```
     */
    init(address: String, port: UInt16? = nil, `protocol`:InetProtocol? = nil, family: ProtocolFamily? = ProtocolFamily.preferred) throws {

        // Regular expression is pretty crude but should break input into ip4v/hostname/ipv6 address and optional port
        guard let match = Address.expression.match(address) else {
            throw Error.Generic("Not an address")
        }

        var port: UInt16? = nil
        if let portString = match.strings[3] {
            port = UInt16(portString)
            if port == nil {
                throw Error.Generic("Not an address")
            }
        }
        
        guard let addressString = match.strings[1] ?? match.strings[2] else {
            throw Error.Generic("Not an address")
        }

        let addresses: [Address] = try Address.addresses(addressString, protocol: `protocol`, family: family)
        guard var address = addresses.first else {
            throw Error.Generic("Could not create address")
        }
        if let port = port {
            address = address.addressWithPort(port)
        }
        self = address
    }

    private static let expression = try! RegularExpression("(?:([\\da-zA-Z0-9_.-]+)|\\[([\\da-fA-F0-9:]+)\\]?)(?::(\\d{1,5}))?")

}
