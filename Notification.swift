//
//  Notification.swift
//  Merchat
//
//  Created by Jeremy Fox on 2/1/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

enum NotificationStyle: UInt {
    case Default
    case Error
    case Success
    case Warning
    case Info
}

class Notification: Equatable {
   
    var scheduledForDate: NSDate
    var title: String?
    var message: String?
    var style: NotificationStyle?
    
    required init(scheduledForDate: NSDate) {
        self.scheduledForDate = scheduledForDate
    }
    
    convenience init(scheduledForDate: NSDate = NSDate(),_ title: String?,_ message: String?,_ style: NotificationStyle) {
        self.init(scheduledForDate: scheduledForDate)
        self.title = title
        self.message = message
        self.style = style
    }
    
    class func scheduledNotificationForDate(date: NSDate = NSDate(),_ title: String?,_ message: String?,_ style: NotificationStyle) {
        let notification = Notification(scheduledForDate: date)
        notification.title = title
        notification.message = message
        notification.style = style
    }
    
}

func ==(lhs: Notification, rhs: Notification) -> Bool {
    return (lhs.scheduledForDate == rhs.scheduledForDate) && (lhs.title == rhs.title) && (lhs.message == rhs.message) && (lhs.style == rhs.style)
}