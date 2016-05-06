//
//  Resolver.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 3/18/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import SwiftUtilities

class Resolver {

    static let sharedInstance = Resolver()

    var lock = NSLock()
    var staticNames: [String: [Address]] = [:]
    var cache: [String: [Address]] = [:]
    let queue = dispatch_queue_create("io.schwa.SwiftIO.Resolver", DISPATCH_QUEUE_SERIAL)

    func addressesForName(name: String) throws -> [Address]? {
        return lock.with() {
            if let addresses = staticNames[name] {
                return addresses
            }
            return nil
        }
    }

    func addressesForName(name: String, callback: Result <[Address]> -> Void) {
        let found: Bool = lock.with() {
            if let addresses = staticNames[name] {
                callback(.Success(addresses))
                return true
            }
            if let addresses = cache[name] {
                callback(.Success(addresses))
                return true
            }
            return false
        }
        if found {
            return
        }
        dispatch_async(queue) {
            [weak self] in

            guard let strong_self = self else {
                return
            }
            let result = tryGivingResult() {
                () -> [Address] in
                let addresses = try strong_self._resolve(name)
                strong_self.lock.with() {
                    strong_self.cache[name] = addresses
                }
                return addresses
            }
            callback(result)
        }
    }

    private func _resolve(hostname: String) throws -> [Address] {
        var addresses: [Address] = []
        var hints = addrinfo()
        hints.ai_flags = AI_ALL | AI_V4MAPPED
        try getaddrinfo(hostname, service: "", hints: hints) {
            let addr = sockaddr_storage(addr: $0.memory.ai_addr, length: Int($0.memory.ai_addrlen))
            let address = Address(sockaddr: addr)
            addresses.append(address)
            return true
        }
        return Array(Set(addresses)).sort(<)
    }
}

// MARK: -

extension Resolver {

    func readHosts() throws {
//        let path = NSBundle.mainBundle().pathForResource("hosts", ofType: nil)!
        let path = "/etc/hosts"
        let hostsFile = try String(contentsOfFile: path)
        let items = hostsFile.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
//            .lazy // lazy takes compile time from 234.3ms to 8498.7ms
            // Filter out empty lines
            .filter() { $0.isEmpty == false }
            // Trim whitespace
            .map() { $0.trimWhitespace() }
            // Remove comments
            .filter() { $0.hasPrefix("#") == false }
            // Break into runs of non-whitespace
            .map() { $0.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).filter() { $0.isEmpty == false } }

        var staticNames: [String: [Address]] = [:]
        try items.forEach() {
            components in
            let address = components[0]
            for name in components.dropFirst() {
                staticNames[name] = (staticNames[name] ?? []) + [try Address(address: address)]
            }
        }

        lock.with() {
            self.staticNames = staticNames
        }
    }
}

// MARK: -

private extension String {
    func trimWhitespace() -> String {
        return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}


// TODO: Move to swiftutilities
private func tryGivingResult <R>(@noescape closure: () throws -> R) -> Result <R> {
    do {
        let value = try closure()
        return .Success(value)
    }
    catch let error {
        return .Failure(error)
    }

}
