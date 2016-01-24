//
//  HTTPServerViewController.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import AppKit

import SwiftIO
import SwiftUtilities


class HTTPServerViewController: NSViewController {

    let port = UInt16(40000)
    var server: Server!

    dynamic var reconnect: Bool = false
    dynamic var state: String? = nil
    dynamic var connected: Bool = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        do {
            try createServer()
        }
        catch let error {
            fatalError("Error: \(error)")
        }
    }
}

extension HTTPServerViewController {

    func createServer() throws {
        let address = try Address(address: "localhost", `protocol`: InetProtocol.TCP, family: ProtocolFamily.INET)
        server = try Server(address: address, port: port)

        server.clientWillConnect = {
            (client) in

            client.stateChanged = {
                (old, new) in
                log?.debug("Client state change: \(old) -> \(new)")
            }


            let requestMessage = HTTPMessage(type: .Request)

            client.readCallback = {
                (result) in

                log?.debug("Server response: \(result)")

                do {
                    if let data = result.value {
                        try data.apply() {
                            (range, buffer) in
                            try requestMessage.write(buffer)
                            return true
                        }

                        //
                        if requestMessage.headerComplete {
                            print(requestMessage.requestMethod)
                            print(requestMessage.requestURL)
                            print(requestMessage.headers)

                            let response = HTTPMessage.response(200)
                            response.body = "Hello world".dataUsingEncoding(NSUTF8StringEncoding)!



                            client.write(DispatchData <Void> (response.serializedData)) {
                                (result) in
                                print(result)

                                client.disconnect() {
                                    (result) in
                                    print(result)
                                }
                            }
                        }



                    }
                }
                catch let error {
                    log?.debug("Error: \(error)")
                }
            }
        }
    }
}


extension HTTPServerViewController {

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

}

// MARK: -

class HTTPMessage {

    enum Type {
        case Request
        case Response
    }

    let message: CFHTTPMessageRef

    class func response(statusCode: Int, statusDescription: String? = nil, httpVersion: String = String(kCFHTTPVersion1_0)) -> HTTPMessage {
        let message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, statusDescription, httpVersion).takeRetainedValue()
        return HTTPMessage(message: message)
    }

    required init(message: CFHTTPMessageRef) {
        self.message = message
    }

    convenience init(type: Type) {
        let message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, type == .Request).takeRetainedValue()
        self.init(message: message)
    }



    func write(buffer: UnsafeBufferPointer <Void>) throws {
        if CFHTTPMessageAppendBytes(message, UnsafePointer <UInt8> (buffer.baseAddress), buffer.count) == false {
            throw Error.Generic("Failed to write")
        }
    }

    var headerComplete: Bool {
        return CFHTTPMessageIsHeaderComplete(message)
    }

    var headers: [String: String] {
        guard let headers = CFHTTPMessageCopyAllHeaderFields(message)?.takeRetainedValue() else {
            fatalError("No headers")
        }
        return headers as NSDictionary as! [String: String]
    }

    var requestURL: NSURL {
        guard let cfURL = CFHTTPMessageCopyRequestURL(message)?.takeRetainedValue() else {
            fatalError("No url")
        }
        return cfURL as NSURL
    }

    var requestMethod: String {
        guard let cfString = CFHTTPMessageCopyRequestMethod(message)?.takeRetainedValue() else {
            fatalError("No request method")
        }
        return cfString as String
    }

    var serializedData: NSData {
        guard let cfData = CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue() else {
            fatalError("No data")
        }
        return cfData as NSData
    }

    var body: NSData {
        get {
            let data = CFHTTPMessageCopyBody(message)?.takeRetainedValue()
            return data!
        }
        set {
            CFHTTPMessageSetBody(message, newValue)
        }

    }




}
