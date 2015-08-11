//
//  RandomAccess.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/11/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

public enum Whence: Int {
    case set = 0
    case current = 1
    case end = 2
}

public protocol RandomAccess {
    func tell() throws -> Int
    func seek(offset:Int, whence:Whence) throws -> Int
}


public protocol RandomAccessInput: RandomAccess {
    func read(offset offset:Int, length:Int) throws -> Buffer <Void>
}

public protocol RandomAccessOutput: RandomAccess {
    func write(offset offset:Int, buffer:UnsafeBufferPointer <Void>) throws
}

