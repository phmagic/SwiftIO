//
//  Connectable.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 3/3/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import SwiftUtilities

public enum ConnectionState {
    case Disconnected
    case Connecting
    case Connected
    case Disconnecting
}

public protocol Connectable {
    associatedtype ConnectionStateType

    var state: ConnectionStateType { get }
    func connect(callback: SwiftUtilities.Result <Void> -> Void)
    func disconnect(callback: SwiftUtilities.Result <Void> -> Void)
}

public extension Connectable where ConnectionStateType == ConnectionState {
    var connected: Bool {
        return state == .Connected
    }
}
