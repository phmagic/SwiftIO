//
//  DatagramReplay.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

enum Type: Int {
    case datagram
}

extension Type: BinaryStreamable {
    func writeTo <T:OutputBinaryStream> (stream:T) throws {
        let value = Int32(self.rawValue)
        try stream.write(value)
    }
}

public func loggingDatagramHandler() throws -> Datagram -> Void {
    let stream = FileStream(url: NSURL(fileURLWithPath: "/Users/schwa/Desktop/test.log"))
    try stream.open()

    return {
        (datagram:Datagram) -> Void in

        let payload = MemoryStream()

        let metadata:[String:AnyObject] = [
            "from": String(datagram.from),
            "timestamp": String(datagram.timestamp),
        ]
        let json = try! NSJSONSerialization.dataWithJSONObject(metadata, options: NSJSONWritingOptions())
        try! payload.write(Int32(json.length))
        try! payload.write(json)

        let data = Buffer <Void> (pointer:datagram.data.bytes, length:datagram.data.length)
        try! payload.write(Int32(data.length))
        try! payload.write(data.bufferPointer)

        let typedData = TypedData(type:Type.datagram, buffer:payload.buffer)

        try! stream.write(typedData)
    }
}

// MARK: -

// TODO: Make T not require BinaryStreamable and move it onto the typedData extension!
public struct TypedData <T:BinaryStreamable> {
    let type:T
    let buffer:Buffer <Void>
}

extension TypedData: BinaryStreamable {
    public func writeTo <Target:OutputBinaryStream> (stream:Target) throws {
        try stream.write(type)
        try stream.write(Int32(buffer.count))
        try stream.write(buffer.bufferPointer)
    }
}

// MARK: -

public protocol OutputBinaryStream {
   func write(buffer:UnsafeBufferPointer <Void>) throws
}

public protocol BinaryStreamable {
    func writeTo <Target:OutputBinaryStream> (stream:Target) throws
}

public extension OutputBinaryStream {
    func write <Target:BinaryStreamable> (value:Target) throws {
        try value.writeTo(self)
    }

    func write(value:Int32) throws {
        var value = value.bigEndian
        let buffer = withUnsafePointer(&value) {
            (pointer:UnsafePointer <Int32>) -> UnsafeBufferPointer <Void> in
            return UnsafeBufferPointer(start: pointer, count: sizeof(Int32))
        }
        try write(buffer)
    }

    func write(string:String, appendNewline: Bool = false) throws {
        let string = appendNewline == true ? string : string + "\n"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let buffer = UnsafeBufferPointer <Void> (start:data.bytes, count:data.length)
        try write(buffer)
    }
}

// MARK: -

extension NSData: BinaryStreamable {
    public func writeTo <Target:OutputBinaryStream> (stream:Target) throws {
        let buffer = UnsafeBufferPointer <Void> (start: bytes, count: length)
        try stream.write(buffer)
    }
}

// MARK: -

public class MemoryStream: OutputBinaryStream {
    private var data:NSMutableData = NSMutableData()

    public var buffer:Buffer <Void> {
        return Buffer <Void> (data: data)
    }

    public func write(buffer:UnsafeBufferPointer <Void>) throws {
        data.appendBytes(buffer.baseAddress, length: buffer.count)
    }
}

// MARK: -

public class FileStream: OutputBinaryStream {

    public let url:NSURL
    public internal(set) var queue:dispatch_queue_t!
    public internal(set) var channel:dispatch_io_t!
    public internal(set) var isOpen:Bool = false

    public init(url:NSURL) {
        self.url = url
    }

    deinit {
        if isOpen == true {
            try! close()
        }
    }

    public func open() throws {
        do {
            guard let path = url.path else {
                throw Error.generic("Could not get path from url.")
            }

            queue = dispatch_queue_create("io.schwa.SwiftIO.FileStream.Serial", DISPATCH_QUEUE_SERIAL)

            channel = path.withCString() {
                return dispatch_io_create_with_path(DISPATCH_IO_STREAM, $0, O_RDWR | O_APPEND | O_CREAT, 0o644, queue) {
                    (error:Int32) -> Void in
                    // TODO: Cleanup
                    let error = NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil)
                    print("CLEANUP: \(error)")
                    self.channel = nil
                    self.queue = nil
                    self.isOpen = false
                }
            }
            guard channel != nil else {
                throw Error.generic("Could not create channel")
            }

            isOpen = true
        }
        catch let error {
            if queue != nil {
                queue = nil
            }
            if channel != nil {
                channel = nil
            }
            throw error
        }
    }

    public func close() throws {
        guard isOpen == true else {
            return
        }
        assert(channel != nil)
        assert(queue != nil)

        dispatch_io_close(channel, 0)
    }

    public func write(buffer:UnsafeBufferPointer <Void>) throws {

        guard isOpen == true else {
            throw Error.generic("Stream not open")
        }

        assert(channel != nil)
        assert(queue != nil)

        let data = dispatch_data_create(buffer.baseAddress, buffer.count, nil, nil)
        dispatch_io_write(channel, 0, data, queue) {
            (success:Bool, data:dispatch_data_t!, error:Int32) -> Void in
            if error != 0 {
                let error = NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil)
                print((success, data, error))
            }
        }
    }
}

enum Error:ErrorType {
    case none
    case generic(String)
    case dispatchIO(Int32)

}