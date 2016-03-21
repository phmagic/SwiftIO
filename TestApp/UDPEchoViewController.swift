//
//  UDPEchoViewController.swift
//  SwiftIO
//
//  Created by Bart Cone on 12/23/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Cocoa

import SwiftIO

class UDPEchoViewController: NSViewController {

    var udpServer: UDPChannel!
    var udpClient: UDPChannel!
    var family: ProtocolFamily?
    let port: UInt16 = 20000

    override func viewDidLoad() {
        super.viewDidLoad()

//        // TODO: On my iMac INET6 breaks and seems to be the default when resolving local host
//        family = .INET
//
//        // server
//        let serverAddress = try! Address(address: "127.0.0.1", port: port, family: family)
//        udpServer = try! UDPChannel(label: "example.udp.server", address: serverAddress) {
//            (datagram) in
//            log?.debug("UDPEcho: Server received - \(datagram)")
//            try! self.udpServer.send(datagram.data, address: datagram.from, writeHandler: nil)
//        }
//
//        udpServer.configureSocket = { socket in
//            socket.socketOptions.reuseAddress = true
//        }
//
//        // client
//        // TODO: UDPChannels should not need an address, just to write.
//        let address = try! Address(address: "127.0.0.1", port: port + 1, family: family)
//
//        udpClient = try! UDPChannel(label: "example.udp.client", address: address) {
//            (datagram) in
//            log?.debug("UDPEcho: Client received - \(datagram)")
//        }
//
//        udpClient.configureSocket = { socket in
//            socket.socketOptions.reuseAddress = true
//        }
    }

    @IBAction func startStopServer(sender: SwitchControl) {
        if sender.on {
            try! udpServer.resume()
            try! udpClient.resume()
        }
        else {
            try! udpServer.cancel()
            try! udpClient.cancel()
        }
    }

    @IBAction func pingServer(sender: AnyObject) {
        let data = "0xDEADBEEF".dataUsingEncoding(NSUTF8StringEncoding)!
        let remoteServer = try! Address(address: "127.0.0.1", family: family, port: port)
        try! udpClient.send(data, address: remoteServer) {
            result in
        }
    }


}
