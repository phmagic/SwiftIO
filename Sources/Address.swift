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
 *  sockaddr generally stores IP address (either IPv4 or IPv6), port, protocol family and type.
 */
public struct Address {

    /// Optional native endian port of the address
    public let port: UInt16?


    /// Create a new Address with a different port
    public func addressWithPort(port: UInt16) -> Address {
        return Address(internalAddress: internalAddress, port: port)
    }

    internal enum InternalAddress {
        case INET(in_addr)
        case INET6(in6_addr)
    }

    internal let internalAddress: InternalAddress

    internal init(internalAddress: InternalAddress, port: UInt16) {
        self.internalAddress = internalAddress
        self.port = port
    }

}

extension Address {

    /// Create an address from a POSIX in_addr (IPV4) structure and optional port
    public init(addr: in_addr, port: UInt16? = nil) {
        internalAddress = .INET(addr)
        self.port = port
    }

    /// Create an address from a POSIX in6_addr (IPV6) structure and optional port
    public init(addr: in6_addr, port: UInt16? = nil) {
        internalAddress = .INET6(addr)
        self.port = port
    }

    public var family: ProtocolFamily {
        return ProtocolFamily(rawValue: addressFamily)!
    }

    internal var addressFamily: Int32 {
        switch internalAddress {
            case .INET:
                return AF_INET
            case .INET6:
                return AF_INET6
        }
    }
}

// MARK: -

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

// MARK: -

extension Address: Hashable {
    public var hashValue: Int {
        // TODO: cheating
        return description.hashValue
    }
}

// MARK: -

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

// MARK: -

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
            return address
        }
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

    /// A string representation of the Address _without_ the port
    public var address: String {
        return tryElseFatalError() {
            return try withUnsafePointer() {
                (inputPtr: UnsafePointer<Void>) -> String in
                return try inet_ntop(addressFamily: self.addressFamily, address: inputPtr)
            }
        }
    }
}

// MARK: sockaddr support

public extension Address {

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
        let addresses: [Address] = try Address.addresses(address, `protocol`: `protocol`, family: family)
        guard var address = addresses.first else {
            throw Error.Generic("Could not create address")
        }
        if let port = port {
            address = address.addressWithPort(port)
        }
        self = address


    }

    static func addresses(hostname: String, `protocol`:InetProtocol? = nil, family: ProtocolFamily? = nil) throws -> [Address] {
        var addresses: [Address] = []

        var hints = addrinfo()
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
            let address = try Address(addr: addr)
            addresses.append(address)
            return true
        }

        let addressSet = Set <Address> (addresses)

        return Array <Address> (addressSet).sort(<)
    }
}

public extension Address {
    static func addressesForInterfaces() throws -> [String: [Address]] {
        let addressesForInterfaces = getAddressesForInterfaces() as! [String: [NSData]]
        let pairs: [(String, [Address])] = try addressesForInterfaces.flatMap() {
            (interface, addressData) -> (String, [Address])? in

            if addressData.count == 0 {
                return nil
            }

            let addresses = try addressData.map() {
                (addressData: NSData) -> Address in
                let sockAddr = UnsafePointer <sockaddr> (addressData.bytes)
                let address = try Address(addr: sockAddr.memory)
                return address
            }
            return (interface, addresses.sort(<))
        }
        return Dictionary <String, [Address]> (pairs)
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
