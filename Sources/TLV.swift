//
//  TLV.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/7/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

// MARK: -

import SwiftUtilities

public typealias BinaryStreamable = protocol <BinaryInputStreamable, BinaryOutputStreamable>

public struct TLVRecord <Type: protocol <BinaryStreamable, Equatable>, Length: protocol <BinaryStreamable, UnsignedIntegerType>> {
    let type: Type
    let data: DispatchData <Void>

    public init(type: Type, data: DispatchData <Void>) {
        self.type = type

//        guard data.length <= Length.max else {
//            throw Error.Generic("Data too big")
//        }

        self.data = data
    }
}

// MARK: -

extension TLVRecord: Equatable {
}

public func == <Type, Length> (lhs: TLVRecord <Type, Length>, rhs: TLVRecord <Type, Length>) -> Bool {
    return lhs.type == rhs.type && lhs.data == rhs.data
}

// MARK: -

extension TLVRecord: BinaryInputStreamable {
    public static func readFrom <Stream: BinaryInputStream> (stream: Stream) throws -> TLVRecord {
        let type: Type = try stream.read()
        let length: Length = try stream.read()
        let data: DispatchData <Void> = try stream.read(length: Int(length.toUIntMax()))
        let record = TLVRecord(type: type, data: data)
        return record
     }
}

// MARK: -

extension TLVRecord: BinaryOutputStreamable {
    public func writeTo <Target: BinaryOutputStream> (stream: Target) throws {
        try stream.write(type)
        let length = Length(UIntMax(data.length))

//        guard length <= Length.max else {
//            throw Error.Generic("Data too big")
//        }

        try stream.write(length)
        try stream.write(data)
    }
}
