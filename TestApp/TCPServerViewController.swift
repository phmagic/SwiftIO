//
//  TCPServerViewController.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import AppKit

import SwiftIO
import SwiftUtilities

class TCPServerViewController: NSViewController {

    typealias Record = TLVRecord <UInt16, UInt16>
    let endianness = Endianness.Big

    let port: UInt16 = 40001
    var server: TCPServer!
    var clientChannel: TCPChannel!
    var count: Int = 0

    dynamic var reconnect: Bool = false
    dynamic var state: String? = nil
    dynamic var connected: Bool = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        do {
            try createServer()
            try createClient()
        }
        catch let error {
            fatalError("Error: \(error)")
        }
    }
}

extension TCPServerViewController {

    func createServer() throws {

//        let address = try Address("localhost:40000")
//        server = try TCPServer(address: address)

        let address = try Address(address: "0.0.0.0", port: self.port)
        server = try TCPServer(address: address)

        server.clientWillConnect = {
            (client) in

            log?.debug("clientWillConnect: \(try! client.socket.getPeer())")

            var buffer = DispatchData <Void> ()
            client.readCallback = {
                (result) in

                log?.debug("Server Got data")

                if case .Success(let data) = result {
                    buffer = buffer + data
                    let (records, remaining) = try! Record.readMultiple(buffer, endianness: self.endianness)
                    for record in records {
                        dispatch_async(dispatch_get_main_queue()) {
                            let string = try! String(data: record.data)
                            SwiftIO.log?.debug("Server received: \(string)")
                        }
                    }
                    buffer = remaining
                }
            }
        }
        server.clientDidDisconnect = {
            (client) in

            log?.debug("clientDidDisconnect")
        }
    }

    func createClient() throws {

        let address = try Address(address: "mote.local.", port: port)

        clientChannel = try TCPChannel(address: address)
        print(clientChannel)

        clientChannel.configureSocket = {
            socket in
        }
        clientChannel.state.addObserver(self, queue: dispatch_get_main_queue()) {
            (old, new) in

            log?.debug("State changed: \(old) -> \(new)")

            self.state = String(new)

            switch (old, new) {
                case (_, .Unconnected):
                    self.connected = false
                case (_, .Connected):
                    self.connected = true
                default:
                    break
            }
        }

        clientChannel.readCallback = {
            (result) in
            if case .Failure(let error) = result {
                log?.debug("Client read callback: \(error)")
                return
            }
        }

        clientChannel.reconnectionDelay = 1.0
        clientChannel.shouldReconnect = {
            return self.reconnect
        }
    }

}


extension TCPServerViewController {

    @IBAction func startStopServer(sender: SwitchControl) {
        if sender.on {
            log?.debug("Server start listening")
            try! server.startListening()
        }
        else {
            log?.debug("Server stop listening")
            try! server.stopListening()
        }
    }

    @IBAction func disconnectAll(sender: AnyObject?) {
        try! server.disconnectAllClients()
    }

    @IBAction func connect(sender: AnyObject?) {
        clientChannel.connect() {
            (result) in

            if case .Failure(let error) = result {
                assert(self.clientChannel.state.value == .Unconnected)
                SwiftIO.log?.debug("\(self.clientChannel): Client connect callback: \(error)")
                return
            }

            for _ in 0..<2 {
                let record = try! Record(type: 100, data: DispatchData <Void> ("Hello world: \(self.count++)"))
                let data = try! record.toDispatchData(self.endianness)
                self.clientChannel!.write(data) {
                    (result) in
                    SwiftIO.log?.debug("Client data writer: \(result)")
                }
            }
        }
    }

    @IBAction func disconnect(sender: AnyObject?) {
        clientChannel.disconnect() {
            (result) in
            SwiftIO.log?.debug("Client disconnect callback: \(result)")
        }
    }

    @IBAction func ping(sender: AnyObject?) {
        let record = try! Record(type: 100, data: DispatchData <Void> ("Hello world: \(count++)"))
        let data = try! record.toDispatchData(self.endianness)
        self.clientChannel!.write(data) {
            (result) in
            SwiftIO.log?.debug("Client wrote data: \(result)")
        }
    }

}


extension String {
    init(data: DispatchData <Void>, encoding: NSStringEncoding = NSUTF8StringEncoding) throws {
        let nsdata = data.toNSData()
        self = NSString(data: nsdata, encoding: encoding) as! String
    }
}
