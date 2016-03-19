//
//  Address+Interfaces.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 3/18/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Foundation

public extension Address {
    static func addressesForInterfaces() throws -> [String: [Address]] {
        let addressesForInterfaces = getAddressesForInterfaces() as! [String: [NSData]]
        let pairs: [(String, [Address])] = addressesForInterfaces.flatMap() {
            (interface, addressData) -> (String, [Address])? in

            if addressData.count == 0 {
                return nil
            }

            let addresses = addressData.map() {
                (addressData: NSData) -> Address in
                let sockAddr = UnsafePointer <sockaddr> (addressData.bytes)
                let address = Address(addr: sockAddr)
                return address
            }
            return (interface, addresses.sort(<))
        }
        return Dictionary <String, [Address]> (pairs)
    }
}

// MARK: -


private extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}
