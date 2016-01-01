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
    
    let remoteServer = try! Address(address: "localhost")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // server
        udpServer = try! UDPChannel(hostname: "localhost", port: 10000) { (dataGram) in
            print("UDPEcho: Server received - \(dataGram)")
            print("UDPEcho: Echo'ing to client")
            try! self.udpServer.send(dataGram.data, address: dataGram.from.0, port: dataGram.from.1, writeHandler: nil)
        }

        // spin up server and its queues
        try! udpServer.resume()
        
        // client
        udpClient = try! UDPChannel(hostname: "localhost", port: 59324) { (dataGram) in
            print("UDPEcho: Client received - \(dataGram)")
        }
        
        // spin up client and its queues
        try! udpClient.resume()
    }

    @IBAction func pingServer(sender: AnyObject) {
        let data = "0xDEADBEEF".dataUsingEncoding(NSUTF8StringEncoding)
        try! udpClient.send(data!, address: remoteServer, port: 10000, writeHandler: nil)
    }
    
}
