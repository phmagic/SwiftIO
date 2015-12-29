//
//  TLV.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/7/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

// MARK: -

import SwiftUtilities

public typealias TLVType = protocol <BinaryStreamable, Equatable, EndianConvertable>
public typealias TLVlength = protocol <BinaryStreamable, UnsignedIntegerType, EndianConvertable>

public struct TLVRecord <Type: TLVType, Length: TLVlength> {
    public let type: Type
    public let data: DispatchData <Void>

    public init(type: Type, data: DispatchData <Void>) {
        self.type = type

        // TODO
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
        let data: DispatchData <Void> = try stream.readData(length: Int(length.toUIntMax()))
        let record = TLVRecord(type: type, data: data)
        return record
     }
}

// MARK: -

extension TLVRecord: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try stream.write(type)
        let length = Length(UIntMax(data.length.toEndianness(stream.endianness)))

        // TODO
//        guard length <= Length.max else {
//            throw Error.Generic("Data too big")
//        }

        try stream.write(length)
        try stream.write(data)
    }
}


// MARK: -

public extension TLVRecord {
    func toDispatchData(endianness: Endianness) throws -> DispatchData <Void> {
        let length = Length(UIntMax(self.data.length))
        let data = DispatchData <Void> ()
            + DispatchData <Void> (value: type.toEndianness(endianness))
            + DispatchData <Void> (value: length.toEndianness(endianness))
            + self.data
        return data
    }
}

// MARK: -

public extension TLVRecord {
    static func read(data: DispatchData <Void>, endianness: Endianness) throws -> (TLVRecord, DispatchData <Void>) {
        // TODO: Endianness
        let (type, data1): (Type, DispatchData <Void>) = try data.split()
        let (length, data2): (Length, DispatchData <Void>) = try data1.split()
        let length2 = Int(length.fromEndianness(endianness).toIntMax())
        let (data3, data4) = try data2.split(length2)
        let record = TLVRecord(type: type.fromEndianness(endianness), data: data3)
        return (record, data4)
    }

    static func read(data: DispatchData <Void>, endianness: Endianness) throws -> ([TLVRecord], DispatchData <Void>) {
        var records: [TLVRecord] = []
        typealias Record = TLVRecord <UInt16, UInt16>
        var remainingData = data
        while remainingData.length > 0 {
            let record: TLVRecord
            (record, remainingData) = try read(data, endianness: endianness)
            records.append(record)
        }
        return (records, remainingData)
    }
}
