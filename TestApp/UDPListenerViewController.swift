//
//  UDPListenerViewController.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/9/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Cocoa

import SwiftIO
import SwiftUtilities

// Testing: `echo "Hello World" | socat - UDP-DATAGRAM:0.0.0.0:1234,broadcast`

class UDPListenerViewController: NSViewController {

    var addressString: String? = "localhost:1234"
    
    var listener: UDPChannel? = nil
    
    func startListening() throws {
        guard let addressString = addressString else {
            return
        }
        let address = try Address(address: addressString, passive: true, mappedIPV4: true)
        log?.debug("Listening on: \(address)")
        listener = UDPChannel(label: "udp-listener", address: address) {
            datagram in

            log?.debug("Received datagram from: \(datagram.from)")

            datagram.data.createMap() {
                data, buffer in

                var string = ""
                hexdump(buffer, zeroBased: true, stream: &string)
                log?.debug("Content: \(string)")
            }

            datagram.data
        }

        try listener?.resume()
    }

    func stopListening() throws {
        listener = nil
    }

    
    @IBAction func startStopListener(sender: SwitchControl) {
        if sender.on {
            log?.debug("Server start listening")
            do {
                try self.startListening()
            }
            catch let error {
                presentError(error as NSError)
            }
        }
        else {
            log?.debug("Server stop listening")
        }
    }
    
    

}
