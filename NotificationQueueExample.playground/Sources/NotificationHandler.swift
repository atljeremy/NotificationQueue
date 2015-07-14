//
//  NotificationHandler.swift
//  Merchat
//
//  Created by Jeremy Fox on 2/1/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

public protocol NotificationHandler : class {
    func canHandle(notification: Notification) -> Bool
    func handle(notification: Notification)
    func isEqualToHandler(handler: NotificationHandler) -> Bool
}

public final class WeakHandler {
    private weak var _handler: NotificationHandler?
    
    init(_ handler: NotificationHandler) {
        _handler = handler
    }
    
    func handler() -> NotificationHandler? {
        return _handler
    }
}
