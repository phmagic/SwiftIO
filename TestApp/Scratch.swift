//
//  Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import AppKit

import SwiftIO
import SwiftUtilities

struct Async {
    static func main(closure:() -> Void) {
        dispatch_async(dispatch_get_main_queue(), closure)
    }
}

//struct Dispatch {
//
//    static func after(delay: NSTimeInterval, queue: dispatch_queue_t, closure:() -> Void) {
//        let time = DISPATCH_TIME_NOW + delay
//        dispatch_after(time, queue, closure)
//    }
//
//}


func label(string: String) -> NSTextField {
    let label = NSTextField()
    label.stringValue = string
    label.editable = false
    label.drawsBackground = false
    label.bordered = false
    label.alignment = .Center
    return label
}

// MARK: -

class LayerView: NSView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        wantsLayer = true
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
    }

    convenience init() {
        self.init(frame: CGRectZero)
    }

    var backgroundColor: NSColor? {
        get {
            if let backgroundColor = layer!.backgroundColor {
                return NSColor(CGColor: backgroundColor)
            }
            else {
                return nil
            }
        }
        set {
            if let backgroundColor = newValue {
                layer!.backgroundColor = backgroundColor.CGColor
            }
            else {
                layer!.backgroundColor = nil
            }
        }
    }

    var borderColor: NSColor? {
        get {
            if let borderColor = layer!.borderColor {
                return NSColor(CGColor: borderColor)
            }
            else {
                return nil
            }
        }
        set {
            if let borderColor = newValue {
                layer!.borderColor = borderColor.CGColor
            }
            else {
                layer!.borderColor = nil
            }
        }
    }

    var borderWidth: CGFloat {
        get {
            return layer!.borderWidth
        }
        set {
            layer!.borderWidth = newValue
        }
    }

    var cornerRadius: CGFloat {
        get {
            return layer!.cornerRadius
        }
        set {
            layer!.cornerRadius = newValue
        }
    }
}

// MARK: -

class SafeSet <Element: AnyObject> {
    private var set = NSMutableSet()
    private var lock = NSLock()
    func insert(value: Element) {
        lock.with() {
            set.addObject(value)
        }
    }
    func remove(value: Element) {
        lock.with() {
            set.removeObject(value)
        }
    }
}

extension SafeSet: SequenceType {
    typealias Generator = ObjectEnumeratorGenerator <Element>

    func generate() -> ObjectEnumeratorGenerator <Element> {
        // Make a copy to allow mutation while enumerating.
        let copy = set.copy() as! NSSet
        return ObjectEnumeratorGenerator(objectEnumerator: copy.objectEnumerator())
    }
}

struct ObjectEnumeratorGenerator <Element: AnyObject>: GeneratorType {
    var objectEnumerator: NSEnumerator

    init(objectEnumerator: NSEnumerator) {
        self.objectEnumerator = objectEnumerator
    }

    mutating func next() -> Element? {
        let nextObject = objectEnumerator.nextObject()
        if nextObject == nil {
            return nil
        }
        guard let next = nextObject as? Element else {
            fatalError("\(nextObject) is not of type \(Element.self)")
        }
        return next
    }

}

// MARK: -
//
//extension TCPChannel {
//
//    static private var key = 1
//
//    func connect(retryDelay retryDelay: NSTimeInterval, callback: Result <Void> -> Void) {
//        var options = Retrier.Options()
//        options.delay = retryDelay
//        connect(retryOptions: options, callback: callback)
//    }
//
//    func connect(retryOptions retryOptions: Retrier.Options, callback: Result <Void> -> Void) {
//        let retrier = Retrier(options: retryOptions) {
//            (retryCallback) in
//            self.connect() {
//                (result: Result <Void>) -> Void in
//
//                if let error = result.error {
//                    if retryCallback(.Failure(error)) == false {
//                        callback(result)
//                        self.retrier = nil
//                    }
//                }
//                else {
//                    retryCallback(.Success())
//                    callback(result)
//                    self.retrier = nil
//                }
//            }
//        }
//        self.retrier = retrier
//        retrier.resume()
//    }
//
//    var retrier: Retrier? {
//        get {
//            return objc_getAssociatedObject(self, &TCPChannel.key) as? Retrier
//        }
//        set {
//            objc_setAssociatedObject(self, &TCPChannel.key, newValue, .OBJC_ASSOCIATION_RETAIN)
//        }
//    }
//
//}
//
//
//
