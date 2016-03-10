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

    let port = UInt16(40000 + arc4random_uniform(1000))
    var server: Server!
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

extension ServerViewController {

    func createServer() throws {
        let address = try Address(address: "localhost", `protocol`: InetProtocol.TCP, family: ProtocolFamily.INET, port: self.port)
        server = try Server(address: address)

        server.clientWillConnect = {
            (client) in

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
    }

    func createClient() throws {
        clientChannel = try TCPChannel(hostname: "127.0.0.1", port: port)

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
                    print(self.clientChannel.socket.socketOptions.all)
                    print(self.clientChannel.socket.socketOptions.tcpAll)
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


extension ServerViewController {

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

        clientChannel.connect(retryDelay: 1) {
            (result) in

            if case .Failure(let error) = result {
                assert(self.clientChannel.state.value == .Unconnected)
                SwiftIO.log?.debug("Client connect callback: \(error)")
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
