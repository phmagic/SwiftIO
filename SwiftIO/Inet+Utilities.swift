//
//  Inet+Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Darwin

public extension in_addr {
    init?(string:String) {
        let (result, address) = string.withCString() {
            (f: UnsafePointer<Int8>) -> (Int32, in_addr) in
            var address = in_addr()
        let result = inet_aton(f, &address)
        return (result, address)
        }
        if result == 0 {
            self = address
        }
        else {
            self = in_addr()
            return nil
        }
    }
}

extension in_addr: CustomStringConvertible {
    public var description: String {
        get {
            let buffer = inet_ntoa(self)
            let s = String(CString: buffer, encoding: NSASCIIStringEncoding)
            return s ?? ""
        }
    }
}

// MARK: -

public func getnameinfo(addr:UnsafePointer<sockaddr>, addrlen:socklen_t, inout hostname:String?, inout service:String?, flags:Int32) -> Int32 {
    var hostnameBuffer = [Int8](count: Int(NI_MAXHOST), repeatedValue: 0)
    var serviceBuffer = [Int8](count: Int(NI_MAXSERV), repeatedValue: 0)
    return hostnameBuffer.withUnsafeMutableBufferPointer() {
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
}

// MARK: -

public func getaddrinfo(hostname:String, service:String, hints:addrinfo, info:UnsafeMutablePointer<UnsafeMutablePointer<addrinfo>>) -> Int32 {
    var hints = hints
    return hostname.withCString() {
        (hostnameBuffer:UnsafePointer <Int8>) -> Int32 in
        return service.withCString() {
            (serviceBuffer:UnsafePointer <Int8>) -> Int32 in
            return getaddrinfo(hostnameBuffer, serviceBuffer, &hints, info)
        }
    }
}

public func getaddrinfo(hostname:String, service:String, hints:addrinfo, block:UnsafePointer<addrinfo> -> Bool) -> Int32 {
    var hints = hints
    var info = UnsafeMutablePointer<addrinfo>()
    let result = hostname.withCString() {
        (hostnameBuffer:UnsafePointer <Int8>) -> Int32 in
        return service.withCString() {
            (serviceBuffer:UnsafePointer <Int8>) -> Int32 in
            return getaddrinfo(hostnameBuffer, serviceBuffer, &hints, &info)
        }
    }
    if result == 0 {
        var current = info
        while current != nil {
            if block(current) == false {
                break
            }
            current = current.memory.ai_next
        }
        freeaddrinfo(info)
    }
    return result
}
