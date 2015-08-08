//
//  ViewController.swift
//  TestApp
//
//  Created by Jonathan Wight on 8/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Cocoa

import SwiftIO

class ViewController: NSViewController {

    var channel:UDPChannel?

    override func viewDidLoad() {
        super.viewDidLoad()

        channel = try! UDPChannel(hostname: "127.0.0.1", port: 1234) {
            print($0)
        }
        try! channel?.resume()

    }


}

