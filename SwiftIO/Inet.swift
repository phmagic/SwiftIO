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

public extension InetProtocol {
    init?(rawValue:Int32) {
        switch rawValue {
            case IPPROTO_TCP:
                self = .TCP
            case IPPROTO_UDP:
                self = .UDP
            default:
                return nil
        }
    }

    var rawValue:Int32 {
        switch self {
            case .TCP:
                return IPPROTO_TCP
            case .UDP:
                return IPPROTO_UDP
        }
    }
}

/**
 An enum representing protocol family supported by sockaddr.

 This is a subset of what is support by sockaddr. But we mostly care about INET and INET6.
 */
public enum ProtocolFamily {
    case INET
    case INET6
}

public extension ProtocolFamily {

    init?(rawValue:Int32) {
        switch rawValue {
            case PF_INET:
                self = .INET
            case PF_INET6:
                self = .INET6
            default:
                return nil
        }
    }
    var rawValue:Int32 {
        switch self {
            case .INET:
                return PF_INET
            case .INET6:
                return PF_INET6
        }
    }
}