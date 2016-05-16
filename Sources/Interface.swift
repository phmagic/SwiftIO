//
//  Interface.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/14/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Foundation

import ifaddrs

public class Interface {

    public static func test() {

        var interfaceAddresses: UnsafeMutablePointer<ifaddrs> = nil

        let result = getifaddrs(&interfaceAddresses)
        if result != 0 {
            fatalError()
        }


        var current = interfaceAddresses

        while current != nil {
            let name = String(CString: current.memory.ifa_name, encoding: NSASCIIStringEncoding)
            let addr = sockaddr_storage(pointer: current.memory.ifa_addr)

            // The other family we'll probably see is AF_LINK - which is hardware addresses (MAC address, firewire address etc). We skip those for now.
            if Set([AF_INET, AF_INET6]).contains(Int32(addr.ss_family)) {
                let address = Address(sockaddr: addr)
                let netmask = Address(sockaddr: sockaddr_storage(pointer: current.memory.ifa_netmask))
                print(name, address, netmask)

                if current.memory.ifa_dstaddr != nil && current.memory.ifa_dstaddr.memory.sa_len > 0 {
                    let dstaddr = Address(sockaddr: sockaddr_storage(pointer: current.memory.ifa_dstaddr))
                    print(dstaddr)
                }

                print(current.memory.ifa_data)
                print(current.memory.ifa_flags)


            }

            current = current.memory.ifa_next
        }







        freeifaddrs(interfaceAddresses)
    }

}