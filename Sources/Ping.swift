//
//  Ping.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/5/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin


//class Ping {
//
//
////struct PingICMPPacket  {
////    var icmpHeader: icmp
////    var packetTimeStamp: timeval
////}
//
//
//    func test() {
//
//
//        connectx(<#T##Int32#>, <#T##UnsafePointer<sa_endpoints_t>#>, <#T##sae_associd_t#>, <#T##UInt32#>, <#T##UnsafePointer<iovec>#>, <#T##UInt32#>, <#T##UnsafeMutablePointer<Int>#>, <#T##UnsafeMutablePointer<sae_connid_t>#>)
//
//        let protocolInformation = getprotobyname("icmp")
//        let handle = socket(AF_INET, SOCK_DGRAM, protocolInformation.memory.p_proto)
//        var receiveSocketBufferSize: UInt32 = 64 * 1024
//        setsockopt(handle, SOL_SOCKET, SO_RCVBUF, &receiveSocketBufferSize, socklen_t(sizeof(UInt32)))
//
//        let t: Double = 10
//        var timeout = timeval(tv_sec: __darwin_time_t(floor(t)), tv_usec: __darwin_suseconds_t((t - floor(t)) * 1000000))
//        setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(sizeof(timeval)))
//
//
//    }
//
//
//
//
//
//
//
//}