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
    let endianess = Endianess.Big

    let port = UInt16(40000 + SwiftUtilities.random.random(uniform: 1000))
    var server: Server!
    var clientChannel: TCPChannel!

    override func viewDidLoad() {
        super.viewDidLoad()

        try! startServer()
        try! startClient()
    }

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

                    let (records, remaining): ([Record], DispatchData <Void>) = try! Record.read(buffer, endianess: self.endianess)
                    for record in records {
                        print("**** \(record)")
                    }
                    buffer = remaining
                    print(buffer)
                }
            }
        }
        try self.server.start()
    }

    func startClient() throws {

        clientChannel = try TCPChannel(hostname: "localhost", port: port)

        clientChannel.readCallback = {
            (result) in
            if let error = result.error {
                print(error)
                return
            }
            if let data = result.value {
            }
        }

        clientChannel.connect() {
            (result) in

            if let error = result.error {
                assert(self.clientChannel.state == .Unconnected)
                print("Connection failure: \(error)")
                return
            }

            for _ in 0..<2 {
                let record = try! Record(type: 100, data: DispatchData <Void> ("Hello world"))
                let data = try! record.toDispatchData(self.endianess)
                self.clientChannel!.write(data) {
                    (result) in
                    print("Write: ", result)
                }
            }
        }
    }
}
