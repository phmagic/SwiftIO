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

extension DispatchData {

    func split <T> () throws -> (T, DispatchData) {
        let (left, right) = split(sizeof(T))
        let value = left.createMap() {
            (data, buffer) in
            return (buffer.toUnsafeBufferPointer() as UnsafeBufferPointer <T>)[0]
        }
        return (value, right)

    }

}




public extension TLVRecord {

    static func read(data: DispatchData <Void>, endianess: Endianess) throws -> (TLVRecord, DispatchData <Void>) {
        let (type, data): (Type, DispatchData <Void>) = try data.split()
        let (length, data2): (Length, DispatchData <Void>) = try data.split()






        let length2 = Int(length.toIntMax())


        let (data3, data4) = data2.split(length2)
        let record = TLVRecord(type: type, data: data3)
        return (record, data4)
    }

     static func read(data: DispatchData <Void>, endianess: Endianess) throws -> ([TLVRecord], DispatchData <Void>) {
        var records: [TLVRecord] = []
        typealias Record = TLVRecord <UInt16, UInt16>
        var remainingData = data
        while remainingData.length > 0 {
            let record: TLVRecord
            (record, remainingData) = try! read(data, endianess: endianess)
            records.append(record)
        }
        return (records, remainingData)
    }
    
}

// MARK: -

public extension TLVRecord {
    func toDispatchData() throws -> DispatchData <Void> {
        let length = Length(UIntMax(self.data.length))
        let data = DispatchData <Void> ()
            + DispatchData <Void> (value: type)
            + DispatchData <Void> (value: length)
            + self.data
        return data
    }
}

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
