//
//  SwitchControl.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/9/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Cocoa

class SwitchControl: NSControl {

    override class func initialize() {
        exposeBinding("on")
    }

    var on: Bool = false {
        didSet {
            if oldValue == on {
                return
            }
            update(animated: true)
            if action != nil && target != nil {
                sendAction(action, to: target)
            }
        }
    }

    var offColor = NSColor.controlShadowColor()
    var onColor = NSColor.keyboardFocusIndicatorColor()

    private var update: (Void -> Void)!

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        NSLayoutConstraint.activateConstraints([
            heightAnchor.constraintEqualToConstant(20),
            widthAnchor.constraintEqualToConstant(60)
        ])


        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: Selector("click:")))

        setup()
    }

    func setup() {

        // Background View

        let backgroundView = LayerView()
        backgroundView.backgroundColor = offColor
        backgroundView.cornerRadius = 2
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        NSLayoutConstraint.activateConstraints([
            backgroundView.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
            backgroundView.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
            backgroundView.topAnchor.constraintEqualToAnchor(topAnchor),
            backgroundView.bottomAnchor.constraintEqualToAnchor(bottomAnchor),
        ])

        // Thumb View

        let thumbView = LayerView()
        thumbView.backgroundColor = .whiteColor()
        thumbView.borderColor = offColor
        thumbView.borderWidth = 1
        thumbView.cornerRadius = 2
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(thumbView)

        var thumbConstraint = thumbView.leadingAnchor.constraintEqualToAnchor(backgroundView.leadingAnchor)

        NSLayoutConstraint.activateConstraints([
            thumbConstraint,
            thumbView.widthAnchor.constraintEqualToAnchor(backgroundView.widthAnchor, multiplier: 0.5),
            thumbView.topAnchor.constraintEqualToAnchor(backgroundView.topAnchor),
            thumbView.bottomAnchor.constraintEqualToAnchor(backgroundView.bottomAnchor),
        ])

        // Leading Guide

        let leadingGuide = NSLayoutGuide()
        backgroundView.addLayoutGuide(leadingGuide)
        NSLayoutConstraint.activateConstraints([
            leadingGuide.widthAnchor.constraintEqualToAnchor(backgroundView.widthAnchor, multiplier: 0.5),
            leadingGuide.trailingAnchor.constraintEqualToAnchor(thumbView.leadingAnchor),
            leadingGuide.topAnchor.constraintEqualToAnchor(backgroundView.topAnchor),
            leadingGuide.bottomAnchor.constraintEqualToAnchor(backgroundView.bottomAnchor),
        ])

        // Leading Label

        let leadingLabel = label("ON")
        leadingLabel.textColor = .whiteColor()
        leadingLabel.font = NSFont.systemFontOfSize(11)
        leadingLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(leadingLabel)

        NSLayoutConstraint.activateConstraints([
            leadingLabel.centerXAnchor.constraintEqualToAnchor(leadingGuide.centerXAnchor),
            leadingLabel.centerYAnchor.constraintEqualToAnchor(leadingGuide.centerYAnchor),
        ])

        // Trailing Guide

        let trailingGuide = NSLayoutGuide()
        backgroundView.addLayoutGuide(trailingGuide)
        NSLayoutConstraint.activateConstraints([
            trailingGuide.leadingAnchor.constraintEqualToAnchor(thumbView.trailingAnchor),
            trailingGuide.widthAnchor.constraintEqualToAnchor(backgroundView.widthAnchor, multiplier: 0.5),
            trailingGuide.topAnchor.constraintEqualToAnchor(backgroundView.topAnchor),
            trailingGuide.bottomAnchor.constraintEqualToAnchor(backgroundView.bottomAnchor),
        ])

        // Trailing Label

        let trailingLabel = label("OFF")
        trailingLabel.textColor = .whiteColor()
        trailingLabel.font = NSFont.systemFontOfSize(11)
        trailingLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(trailingLabel)

        NSLayoutConstraint.activateConstraints([
            trailingLabel.centerXAnchor.constraintEqualToAnchor(trailingGuide.centerXAnchor),
            trailingLabel.centerYAnchor.constraintEqualToAnchor(trailingGuide.centerYAnchor),
        ])

        // Update Closure

        update = {
            let color = self.on ? self.onColor : self.offColor
            backgroundView.backgroundColor = color
            thumbView.borderColor = color

            thumbConstraint.active = false
            thumbConstraint = nil

            if self.on == false {
                thumbConstraint = thumbView.leadingAnchor.constraintEqualToAnchor(backgroundView.leadingAnchor)
            }
            else {
                thumbConstraint = thumbView.leadingAnchor.constraintEqualToAnchor(backgroundView.centerXAnchor)
            }
            thumbConstraint.active = true
        }
    }

    func update(animated animated: Bool) {

        if animated == false {
            update()
        }
        else {
            NSAnimationContext.runAnimationGroup({ context -> Void in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                context.allowsImplicitAnimation = true
                self.update()
                self.layoutSubtreeIfNeeded()
                }) { () -> Void in
            }
        }
    }


    func click(gestureRecognizer: NSClickGestureRecognizer) {
        on = !on
    }


}
