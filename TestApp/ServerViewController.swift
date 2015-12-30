//
//  ServerViewController.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import AppKit

import SwiftIO
import SwiftUtilities

class ServerViewController: NSViewController {

    typealias Record = TLVRecord <UInt16, UInt16>
    let endianness = Endianness.Big

    let port = UInt16(40000 + SwiftUtilities.random.random(uniform: 1000))
    var server: Server!
    var clientChannel: TCPChannel!
    var count: Int = 0

    dynamic var log: String = ""

    dynamic var connected: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        try! startServer()
        try! startClient()
    }

}

extension ServerViewController {

    @IBAction func connect(sender: AnyObject?) {
        clientChannel.connect() {
            (result) in
            self.log_debug(result)
        }
    }

    @IBAction func disconnect(sender: AnyObject?) {
        clientChannel.disconnect() {
            (result) in
            self.log_debug(result)
        }
    }

    @IBAction func ping(sender: AnyObject?) {
        let record = try! Record(type: 100, data: DispatchData <Void> ("Hello world: \(count++)"))
        let data = try! record.toDispatchData(self.endianness)
        self.clientChannel!.write(data) {
            (result) in
            self.log_debug(result)
        }
    }

}


extension String {
    init(data: DispatchData <Void>, encoding: NSStringEncoding = NSUTF8StringEncoding) throws {
        let nsdata = data.toNSData()
        self = NSString(data: nsdata, encoding: encoding) as! String
    }

}

extension ServerViewController {

    func startServer() throws {
        let address = try Address(address: "localhost", `protocol`: InetProtocol.TCP, family: ProtocolFamily.INET)
        server = try Server(address: address, port: port)

        server.clientWillConnect = {
            (client) in

            var buffer = DispatchData <Void> ()

            client.readCallback = {
                (result) in

                if let data = result.value {

                    buffer = buffer + data

                    let (records, remaining) = try! Record.readMultiple(buffer, endianness: self.endianness)
                    for record in records {

                        dispatch_async(dispatch_get_main_queue()) {
                            let string = try! String(data: record.data)
                            self.log_debug(string)
                        }
                    }
                    buffer = remaining
                }
            }
        }
        try self.server.start()
    }

    func startClient() throws {

        clientChannel = try TCPChannel(hostname: "localhost", port: port)

        clientChannel.stateChangeCallback = {
            (old, new) in

            switch (old, new) {
                case (_, .Unconnected):
                    dispatch_async(dispatch_get_main_queue()) {
                        self.connected = false
                    }
                case (_, .Connected):
                    dispatch_async(dispatch_get_main_queue()) {
                        self.connected = true
                    }
                default:
                    break
            }
        }

        clientChannel.readCallback = {
            (result) in
            if let error = result.error {
                print(error)
                return
            }
//            if let data = result.value {
//            }
        }

        clientChannel.connect() {
            (result) in

            if let error = result.error {
                assert(self.clientChannel.state == .Unconnected)
                self.log_debug(error)
                return
            }

            for _ in 0..<2 {
                let record = try! Record(type: 100, data: DispatchData <Void> ("Hello world: \(self.count++)"))
                let data = try! record.toDispatchData(self.endianness)
                self.clientChannel!.write(data) {
                    (result) in
                    self.log_debug(result)
                }
            }
        }
    }

    func log_debug(value: Any) {
        dispatch_async(dispatch_get_main_queue()) {
            self.log += String(value) + "\n"
        }
    }
}
