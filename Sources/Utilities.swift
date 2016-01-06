//
//  Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/10/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import SwiftUtilities

// TODO: Move to SwiftUtilities
public class Atomic <T> {
    public var value: T {
        get {
            return lock.with() {
                return internalValue
            }
        }
        set {
            var oldValue: T?
            lock.with() {
                oldValue = internalValue
                internalValue = newValue
            }
            valueChanged?(oldValue!, newValue)
        }
    }
    private var internalValue: T
    private var lock: Locking
    public var valueChanged: ((T, T) -> Void)?

    public init(_ value: T, lock: Locking = NSLock(), valueChanged: ((T, T) -> Void)? = nil) {
        self.internalValue = value
        self.lock = lock
        self.valueChanged = valueChanged
    }
}


