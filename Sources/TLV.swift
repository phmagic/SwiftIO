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
    public static func readFrom(stream: BinaryInputStream) throws -> TLVRecord {
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
    static func read(data: DispatchData <Void>, endianness: Endianness) throws -> (TLVRecord?, DispatchData <Void>) {
        // If we don't have enough data to read the TLV header exit
        if data.length < (sizeof(Type) + sizeof(Length)) {
//            print("Not enough data for header")
            return (nil, data)
        }
        return try data.split() {
            (type: Type, remaining: DispatchData <Void>) in
            // Convert the type from endianness
            let type = type.fromEndianness(endianness)
            return try remaining.split() {
                (length: Length, remaining: DispatchData <Void>) in
                // Convert the length from endianness
                let length = Int(length.fromEndianness(endianness).toIntMax())
                // If we don't have enough remaining data to read the payload: exit.
                if remaining.length < length {
//                    print("Not enough data for payload (got: \(remaining.length), needed: \(length))")
                    return (nil, data)
                }
                // Get the payload.
                return try remaining.split(length) {
                    (payload, remaining) in
                    // Produce a record.
                    let record = TLVRecord(type: type.fromEndianness(endianness), data: payload)
                    return (record, remaining)
                }
            }
        }
    }

    static func readMultiple(data: DispatchData <Void>, endianness: Endianness) throws -> ([TLVRecord], DispatchData <Void>) {
        var records: [TLVRecord] = []
        var data = data
        while true {
            let (maybeRecord, remainingData) = try read(data, endianness: endianness)
            guard let record = maybeRecord else {
                break
            }
            records.append(record)
            data = remainingData
        }
        return (records, data)
    }
}

// TODO: Move to SwiftUtilities?
private extension DispatchData {
    func split<T, R>(closure: (T, DispatchData) throws -> R) throws -> R{
        let (value, remaining): (T, DispatchData) = try split()
        return try closure(value, remaining)
    }

    func split <R> (startIndex: Int, closure: (DispatchData, DispatchData) throws -> R) throws -> R {
        let (left, right) = try split(startIndex)
        return try closure(left, right)
    }
}


