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
                return _value
            }
        }
        set {
            let valueChanged: (Void -> Void)? = lock.with() {
                let oldValue = _value
                _value = newValue
                guard let valueChanged = _valueChanged else {
                    return nil
                }
                return {
                    valueChanged(oldValue, newValue)
                }
            }
            valueChanged?()
        }
    }

    /// Called whenever value changes. NOT called during init.
    public var valueChanged: ((T, T) -> Void)? {
        get {
            return lock.with() {
                return _valueChanged
            }
        }
        set {
            lock.with() {
                _valueChanged = newValue
            }
        }
    }

    private var lock: Locking

    private var _value: T
    private var _valueChanged: ((T, T) -> Void)?

    /** - Parameters:
            - Parameter value: Initial value.
            - Parameter lock: Instance conforming to `Locking`. Used to protect access to `value`. The same lock can be shared between multiple Atomic instances.
            - Parameter valueChanged: Closure called whenever value is changed
    */
    public init(_ value: T, lock: Locking = NSLock(), valueChanged: ((T, T) -> Void)? = nil) {
        self._value = value
        self.lock = lock
        self._valueChanged = valueChanged
    }

}


public extension Atomic {

    /// Perform a locking transaction on the instance.
//    func with <R> (@noescape closure: T -> R) -> R {
//        return lock.with() {
//            return closure(value)
//        }
//    }

    /// Perform a locking transaction on the instance. This version allows you to modify the value.
    func with <R> (@noescape closure: inout T -> R) -> R {
        return lock.with() {
            return closure(&_value)
        }
    }


}

// MARK: -



