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
public struct Address {

    enum InternalAddress {
        case INET(in_addr)
        case INET6(in6_addr)
    }

    let internalAddress:InternalAddress

    init(addr:in_addr) {
        internalAddress = .INET(addr)
    }

    init(addr:in6_addr) {
        internalAddress = .INET6(addr)
    }

    var addressFamily:Int32 {
        switch internalAddress {
            case .INET:
                return AF_INET
            case .INET6:
                return AF_INET6
        }
    }
}

extension Address: Equatable {
}

public func ==(lhs: Address, rhs: Address) -> Bool {
    switch (lhs.internalAddress, rhs.internalAddress) {
        case (.INET(let lhs_addr), .INET(let rhs_addr)):
            return lhs_addr == rhs_addr
        case (.INET6(let lhs_addr), .INET6(let rhs_addr)):
            return lhs_addr == rhs_addr
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
        switch internalAddress {
            case .INET:
                return "INET(\(address))"
            case .INET6:
                return "INET6(\(address))"
        }
    }
}

extension Address: CustomReflectable {
    public func customMirror() -> Mirror {
        return Mirror(self, children: [
            "family": String(addressFamily),
            "address": String(address),
        ])
    }
}

// MARK: -

extension Address {
    public func withUnsafePointer <Result> (@noescape body: UnsafePointer<Void> -> Result) -> Result {
        switch internalAddress {
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


// MARK: -

extension Address {
    public var address:String {
        return withUnsafePointer() {
            (inputPtr:UnsafePointer<Void>) -> String in
            return try! inet_ntop(addressFamily: addressFamily, address: inputPtr)
        }
    }
}

// MARK: sockaddr support

public extension Address {

    init(addr:sockaddr) throws {
        switch Int32(addr.sa_family) {
            case AF_INET:
                let sockaddr = addr.to_sockaddr_in()
                internalAddress = .INET(sockaddr.sin_addr)
            case AF_INET6:
                let sockaddr = addr.to_sockaddr_in6()
                internalAddress = .INET6(sockaddr.sin6_addr)
            default:
                throw Error.generic("Invalid sockaddr family")
        }
    }

    func to_sockaddr(port port:UInt16) -> sockaddr {
        switch internalAddress {
            case .INET(let addr):
                return sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: in_port_t(port.networkEndian), sin_addr: addr).to_sockaddr()
            case .INET6(let addr):
                return sockaddr_in6(sin6_family: sa_family_t(AF_INET), sin6_port: in_port_t(port.networkEndian), sin6_addr: addr).to_sockaddr()
        }
    }
}

// MARK: Hostname support

public extension Address {

    init(address:String, `protocol`:InetProtocol? = nil, family:ProtocolFamily? = nil) throws {
        let addresses:[Address] = try Address.addresses(address, family: family)
        self = addresses.first!
    }

    static func addresses(hostname:String, `protocol`:InetProtocol? = nil, family:ProtocolFamily? = nil) throws -> [(Address,InetProtocol,ProtocolFamily,String?)] {
        var results:[(Address,InetProtocol,ProtocolFamily,String?)] = []

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
            let address = try! Address(addr:addr)
            precondition(socklen_t(addr.sa_len) == $0.memory.ai_addrlen)

            let family = ProtocolFamily(rawValue:addrinfo.ai_family)
            let `protocol` = InetProtocol(rawValue:addrinfo.ai_protocol)
            var canonicalName:String? = nil

            if addrinfo.ai_canonname != nil {
                canonicalName = String(CString: addrinfo.ai_canonname, encoding: NSASCIIStringEncoding)
            }

            let result = (address,`protocol`!,family!,canonicalName)
            results.append(result)


//    public var ai_family: Int32 /* PF_xxx */
//    public var ai_socktype: Int32 /* SOCK_xxx */
//    public var ai_protocol: Int32 /* 0 or IPPROTO_xxx for IPv4 and IPv6 */
//    public var ai_canonname: UnsafeMutablePointer<Int8> /* canonical name for hostname */


            return true
        }

        return results
    }


    static func addresses(hostname:String, `protocol`:InetProtocol? = nil, family:ProtocolFamily? = nil) throws -> [Address] {
        var addresses:[Address] = []

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
            let address = try! Address(addr:addr)
            precondition(socklen_t(addr.sa_len) == $0.memory.ai_addrlen)
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
