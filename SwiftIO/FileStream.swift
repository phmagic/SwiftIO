//
//  FileStream.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Foundation

import SwiftUtilities

public class FileStream: BinaryInputStream, BinaryOutputStream {

    public struct Mode: OptionSetType {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let Read = Mode(rawValue: 1)
        public static let Write = Mode(rawValue: 2)
        public static let ReadWrite = Mode(rawValue: Read.rawValue | Write.rawValue)

        func oflags() -> Int32 {
            switch rawValue {
                case Mode.Read.rawValue:
                    return O_RDONLY
                case Mode.Write.rawValue:
                    return O_WRONLY
                case Mode.ReadWrite.rawValue:
                    return O_RDWR
                default:
                    preconditionFailure("Invalid flags")
            }
        }
    }


    public let url:NSURL
    public internal(set) var isOpen:Bool = false

    public init(url:NSURL) {
        self.url = url
    }

    deinit {
        if isOpen == true {
            try! close()
        }
    }

    var fd:Int32!

    public func open(mode:Mode = Mode.Read) throws {
        do {
            guard let path = url.path else {
                throw Error.generic("Could not get path from url.")
            }

            let flags:Int32 = mode.oflags() | O_APPEND | O_CREAT

            let fd = path.withCString() {
                return Darwin.open($0, flags, 0o644)
            }
            guard fd > 0 else {
                throw Error.posix(errno, "Could not open file.")
            }

            isOpen = true
            self.fd = fd
        }
        catch let error {

            throw error
        }
    }

    public func close() throws {
        guard isOpen == true else {
            return
        }
    }

    public func write(buffer:UnsafeBufferPointer <Void>) throws {

        guard isOpen == true else {
            throw Error.generic("Stream not open")
        }

        let result = Darwin.write(fd, buffer.baseAddress, buffer.count)
        if result < 0 {
            throw Error.posix(Int32(result), "write failed")
        }
    }

    public func read(length:Int) throws -> Buffer <Void> {
        guard isOpen == true else {
            throw Error.generic("Stream not open")
        }

        if length <= 0 {
            throw Error.generic("Does not support nil length yet")
        }

        guard let data = NSMutableData(length:length ?? 0) else {
            throw Error.generic("Could not allocate data of length")
        }

        let result = Darwin.read(fd, data.mutableBytes, data.length)
        if result < 0 {
            throw Error.posix(Int32(result), "Read failed.")
        }

        data.length = result

        return Buffer(data:data)
    }
}

