//
//  NotificationHandler.swift
//  Merchat
//
//  Created by Jeremy Fox on 2/1/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

public protocol NotificationHandler : class {
    
    /**
     Used to tell the `NotificationQueue` if the `NotificationHandler` can handle the `notification`
     */
    func canHandle(_ notification: Notification) -> Bool
    
    /**
     Used the perform an action with this given `notification`. This will only be called if `canHandle(notification:)` returns `true`.
     */
    func handle(_ notification: Notification)
    
    /**
     Used to determine if a `NotificationHandler` instance is equeal to `handler`
     */
    func isEqualToHandler(_ handler: NotificationHandler) -> Bool
}

public final class WeakHandler {
    fileprivate(set) weak var handler: NotificationHandler?
    
    init(_ handler: NotificationHandler) {
        self.handler = handler
    }
}
