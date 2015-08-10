//
//  Inet.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

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