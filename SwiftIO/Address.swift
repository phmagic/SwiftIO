//
//  Address.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

/**
 *  A wrapper for a POSIX sockaddr structure.
 *
 *  sockaddr generally store IP address (either IPv4 or IPv6), port, protocol family and type.
 */
public struct Address {
    public let addr:Buffer <sockaddr>!

    public init(addr:Buffer <sockaddr>) {
        self.addr = addr
    }

    public var hostname:String {
        mutating get {
            if _hostname == nil {
                var service:String? = nil
                getnameinfo(addr.baseAddress, addrlen: socklen_t(addr.length), hostname: &_hostname, service: &service, flags: 0)
            }
            return _hostname!
        }
    }

    private var _hostname:String?

    /// Return the service of the address, this is either a numberic port (returned as a string) or the service name if a none type
    public var service:String {
        mutating get {
            if _service == nil {
                var hostname:String? = nil
                getnameinfo(addr.baseAddress, addrlen: socklen_t(addr.length), hostname: &hostname, service: &_service, flags: 0)
            }
            return _service!
        }
    }

    private var _service:String?

     /// Return the port
    public var port:Int16 {
        mutating get {
            if _port == nil {
                var hostname:String? = nil
                var service:String? = nil
                getnameinfo(addr.baseAddress, addrlen: socklen_t(addr.length), hostname: &hostname, service: &service, flags: NI_NUMERICSERV)
                _port = Int16((service! as NSString).integerValue)
            }
            return _port!
        }
    }

    private var _port:Int16?

}

// MARK: -

/**
 An enum representing Inet protocols supported by sockaddr.

 This is a subset of what is support by sockaddr. But we mostly care about TCP and UDP.
 */
public enum InetProtocol {
    case TCP
    case UDP
}

/**
 An enum representing protocol family supported by sockaddr.

 This is a subset of what is support by sockaddr. But we mostly care about INET and INET6.
 */
public enum ProtocolFamily {
    case INET
    case INET6
}

// MARK: -

extension Address: CustomStringConvertible {
    public var description: String {

        var copy = self


        return "\(copy.hostname):\(copy.service)"
    }
}

public extension Address {


    public var as_sockaddr_in:sockaddr_in? {
        return protocolFamily == .INET ? UnsafePointer <sockaddr_in>(addr.baseAddress).memory : nil
    }

    public var as_sockaddr_in6:sockaddr_in6? {
        return protocolFamily == .INET ? UnsafePointer <sockaddr_in6>(addr.baseAddress).memory : nil
    }

    public var protocolFamily:ProtocolFamily? {
        switch addr.baseAddress.memory.sa_family {
            case sa_family_t(PF_INET):
                return .INET
            case sa_family_t(PF_INET6):
                return .INET6
            default:
                return nil
        }
    }
}

// MARK: -

public extension Address {

    /**
     Create an Address object from a POSIX sockaddr structure and length
     */
    init(addr:UnsafePointer<sockaddr>, addrlen:socklen_t) {
        assert(socklen_t(addr.memory.sa_len) == addrlen)
        self.init(addr:Buffer <sockaddr> (pointer:addr, length:Int(addrlen)))
    }

    /**
     Convenience (and slightly esoteric) method to create an Address by providing a closure with a sockaddr and length.
     */
    static func with(@noescape context:(UnsafeMutablePointer <sockaddr>, inout socklen_t) -> Void) -> Address {
        var addressData = Array <Int8> (count:Int(SOCK_MAXADDRLEN), repeatedValue:0)
        return addressData.withUnsafeMutableBufferPointer() {
            (inout ptr:UnsafeMutableBufferPointer <Int8>) -> Address in

            let addr = UnsafeMutablePointer <sockaddr> (ptr.baseAddress)
            var addrlen = socklen_t(SOCK_MAXADDRLEN)

            context(addr, &addrlen)

            return Address(addr: addr, addrlen: addrlen)
        }
    }
}

public extension Address {

    /**
     Create zero or more Address objects satisfying the parameters passed in.
     
     This is a "nice" wrapper around POSIX.getaddrinfo.

     - parameter hostname:   <#hostname description#>
     - parameter service:    <#service description#>
     - parameter `protocol`: <#`protocol` description#>
     - parameter family:     <#family description#>

     - returns: <#return value description#>
     */
    static func addresses(hostname:String, service:String, `protocol`:InetProtocol = .TCP, family:ProtocolFamily? = nil) -> [Address] {
        var addresses:[Address] = []

        var hints = addrinfo()
        hints.ai_flags = AI_CANONNAME | AI_V4MAPPED
        hints.ai_protocol = `protocol`.rawValue
        if let family = family {
            hints.ai_family = family.rawValue
        }

        let result = getaddrinfo(hostname, service: service, hints: hints) {
            let ptr = UnsafePointer <sockaddr> ($0.memory.ai_addr)
            let address = Address(addr: ptr, addrlen: $0.memory.ai_addrlen)
            addresses.append(address)
            return true
        }

        assert(result == 0)

        return addresses
    }

    init(string:String) {
        // TODO: This is crude.

        let components = string.componentsSeparatedByString(":")
        let hostname = components[0]
        let service = components[1]

        self = Address.addresses(hostname, service: service).first!
    }
}


// MARK: -

public extension InetProtocol {
    var rawValue:Int32 {
        switch self {
            case .TCP:
                return IPPROTO_TCP
            case .UDP:
                return IPPROTO_UDP
        }
    }
}

public extension ProtocolFamily {
    var rawValue:Int32 {
        switch self {
            case .INET:
                return PF_INET
            case .INET6:
                return PF_INET6
        }
    }
}