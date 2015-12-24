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

    var udp: UDPChannel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        udp = try! UDPChannel(hostname: "localhost", port: 10000) { (data) in
            print(data)
        }
        
        try! udp.resume()
    }
    
}
