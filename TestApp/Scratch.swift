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
        self.init(frame: CGRect.zero)
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
