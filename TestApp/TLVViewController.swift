//
//  TLVViewController.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import AppKit

import SwiftUtilities
import SwiftIO

class TLVViewController: NSViewController {

    var clientChannel: TCPChannel!
    var task: NSTask?
    dynamic var connected: Bool = false

    dynamic var input: String?
    dynamic var output: String?

    override func viewDidLoad() {
        super.viewDidLoad()

//        // socat TCP4-LISTEN:12345,reuseaddr exec:'tr A-Z a-z',pty,raw,echo=0
//        task = NSTask.launchedTaskWithLaunchPath("/usr/local/bin/socat", arguments: ["TCP4-LISTEN:12346,reuseaddr", "exec:'tr a-z A-Z',pty,raw,echo=0"])
//        sleep(1)
//
//        clientChannel = try! TCPChannel(hostname: "localhost", port: 12346)
//        clientChannel.stateChangeCallback = {
//            (old, new) in
//            print("STATE CHANGE: \(old) -> \(new)")
//        }
//
//        clientChannel.shouldReconnect = {
//            assert(self.clientChannel.state == .Unconnected)
//            print("Disconnected!")
//
//            Async.main() {
//                self.updateConnected()
//            }
//            return true
//        }
//
//        clientChannel.readCallback = {
//            (result) in
//            if let error = result.error {
//                print(error)
//                return
//            }
//            if let data = result.value {
//                let string = String(data: data.toNSData(), encoding:NSUTF8StringEncoding)!
//
//                Async.main() {
//                    self.output = string
//                    self.updateConnected()
//                }
//            }
//        }
//
//        clientChannel.connect() {
//            (result) in
//
//            Async.main() {
//                self.updateConnected()
//            }
//
//            if let error = result.error {
//                assert(self.clientChannel.state == .Unconnected)
//                print("Connection failure: \(error)")
//                return
//            }
//
//            let data = "Hello world".dataUsingEncoding(NSUTF8StringEncoding)!
//            let dispatchData = DispatchData <Void> (start: data.bytes, count: data.length)
//            self.clientChannel!.write(dispatchData) {
//                (result) in
//                print("Write: ", result)
//            }
//        }
    }

    @IBAction func connect(sender:AnyObject?) {
        clientChannel.connect() {
            (result) in
            print("Connect \(result)")
            self.updateConnected()
        }
    }

    @IBAction func disconnect(sender:AnyObject?) {
        clientChannel.disconnect() {
            (result) in
            print("Disconnect \(result)")
        }
    }

    @IBAction func write(sender:AnyObject?) {

        guard let input = input else {
            return
        }

        let data = input.dataUsingEncoding(NSUTF8StringEncoding)!
        let dispatchData = DispatchData <Void> (start: data.bytes, count: data.length)
        self.clientChannel!.write(dispatchData) {
            (result) in
            print("Write: ", result)
        }

    }

    func updateConnected() {
        connected = clientChannel.state == .Connected
        print(clientChannel.state, connected)
    }

}
