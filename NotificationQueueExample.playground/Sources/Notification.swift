//
//  Notification.swift
//  Merchat
//
//  Created by Jeremy Fox on 2/1/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

public enum NotificationStyle: UInt {
    case `default`
    case error
    case success
    case warning
    case info
}

public class Notification: Equatable {
   
    public var scheduledForDate: Date
    public var title: String?
    public var message: String?
    public var style: NotificationStyle?
    
    public required init(scheduled `for`: Date = Date(), title: String?, message: String?, style: NotificationStyle = .default) {
        self.scheduledForDate = `for`
        self.title = title
        self.message = message
        self.style = style
    }
    
}

public func ==(lhs: Notification, rhs: Notification) -> Bool {
    return (lhs.scheduledForDate == rhs.scheduledForDate) && (lhs.title == rhs.title) && (lhs.message == rhs.message) && (lhs.style == rhs.style)
}
