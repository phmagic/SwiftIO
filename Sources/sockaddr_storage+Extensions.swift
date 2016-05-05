//
//  sockaddr_storage.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/5/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin

/**
    Convenience extension to make going from sockaddr_storage to/from other sockaddr structures easy
*/
public extension sockaddr_storage {

    init(sockaddr: sockaddr_in) {
        var copy = sockaddr
        self = sockaddr_storage()
        memcpy(&self, &copy, sizeof(in_addr))
    }

    init(addr: in_addr, port: UInt16) {
        let sockaddr = sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: in_port_t(port.networkEndian), sin_addr: addr)
        self = sockaddr_storage(sockaddr: sockaddr)
    }

    init(sockaddr: sockaddr_in6) {
        var copy = sockaddr
        self = sockaddr_storage()
        memcpy(&self, &copy, sizeof(in_addr))
    }

    init(addr: in6_addr, port: UInt16) {
        let sockaddr = sockaddr_in6(sin6_family: sa_family_t(AF_INET6), sin6_port: in_port_t(port.networkEndian), sin6_addr: addr)
        self = sockaddr_storage(sockaddr: sockaddr)
    }

    init(addr: UnsafePointer <sockaddr>, length: Int) {
        precondition((addr.memory.sa_family == sa_family_t(AF_INET) && length == sizeof(sockaddr_in)) || (addr.memory.sa_family == sa_family_t(AF_INET6) && length == sizeof(sockaddr_in6)))
        self = sockaddr_storage()
        memcpy(&self, addr, length)
    }

}
