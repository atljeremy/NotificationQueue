//
//  NotificationScheduler.swift
//  Merchat
//
//  Created by Jeremy Fox on 2/1/15.
//  Copyright (c) 2015 Jeremy Fox. All rights reserved.
//

import Foundation

/*
    Examples:

    var date: NSDate
    date = 10.seconds.fromNow
    date = 1.day.ago
    date = 2.days.from(someDate)
    date = NSDate() + 3.days

    if dateOne < dateTwo {
        // dateOne is older than dateTwo
    }

    if dateOne > dateTwo {
        // dateOne is more recent than dateTwo
    }

    if dateOne <= dateTwo {
        // dateOne is older than or equal to dateTwo
    }

    if dateOne >= dateTwo {
        // dateOne is more recent or equal to dateTwo
    }

    if dateOne == dateTwo {
        // dateOne is equal to dateTwo
    }
*/

extension NSDate: Comparable {
    
}

func + (date: NSDate, timeInterval: NSTimeInterval) -> NSDate {
    return date.dateByAddingTimeInterval(timeInterval)
}

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    if lhs.compare(rhs) == .OrderedSame {
        return true
    }
    return false
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    if lhs.compare(rhs) == .OrderedAscending {
        return true
    }
    return false
}

extension NSTimeInterval {
    var second: NSTimeInterval {
        return seconds
    }
    
    var seconds: NSTimeInterval {
        return self
    }
    
    var minute: NSTimeInterval {
        return minutes
    }
    
    var minutes: NSTimeInterval {
        let minutesInADay = 1_440 as NSTimeInterval
        return self * minutesInADay
    }
    
    var day: NSTimeInterval {
        return days
    }
    
    var days: NSTimeInterval {
        let secondsInADay = 86_400 as NSTimeInterval
        return self * secondsInADay
    }
    
    var fromNow: NSDate {
        let timeInterval = self
        return NSDate().dateByAddingTimeInterval(timeInterval)
    }
    
    func from(date: NSDate) -> NSDate {
        let timeInterval = self
        return date.dateByAddingTimeInterval(timeInterval)
    }
    
    var ago: NSDate {
        let timeInterval = self
        return NSDate().dateByAddingTimeInterval(-timeInterval)
    }
}

class NotificationQueue: CollectionType {
    
    private var _timer: NSTimer!
    private var _timeInterval: NSTimeInterval
    private var _queue = [Notification]()
    private var _handlers = [WeakHandler]()
    private let _handlerDispatchQueue = dispatch_queue_create("com.merchcat.NotificationQueue.SynchronousHandlerQueue", nil)
    private let _notificationDispatchQueue = dispatch_queue_create("com.merchcat.NotificationQueue.SynchronousHandlerQueue", nil)
    
    internal typealias Index = Int
    internal var startIndex: Index { return 0 }
    internal var endIndex: Index { return _queue.endIndex }

    var count: Int { return _queue.count }
    var isEmpty: Bool { return _queue.isEmpty }
    
    subscript (_i: Index) -> Notification {
        get {
            let notification = _queue[_i]
            return notification
        }
        set(newValue) {
            if !_queue.contains(newValue) {
                _queue.insert(newValue, atIndex: _i)
            }
        }
    }
    
    func generate() -> AnyGenerator<Notification> {
        var notificationGenerator = _queue.generate()
        return anyGenerator {
            if let notification = notificationGenerator.next() {
                return notification
            }
            return nil
        }
    }
    
    private class var _sharedQueue: NotificationQueue {
        struct Static {
            static let instance = NotificationQueue(timeInterval: 0.1)
        }
        return Static.instance
    }
    
    class func sharedQueue() -> NotificationQueue {
        return _sharedQueue
    }
    
    init(timeInterval: NSTimeInterval) {
        _timeInterval = timeInterval
        NSThread.detachNewThreadSelector("createTimer", toTarget: self, withObject: nil)
    }
    
    @objc private func createTimer() {
        NSThread.currentThread().name = "NotificationQueueTimerThread"
        let runLoop = NSRunLoop.currentRunLoop()
        _timer = NSTimer.scheduledTimerWithTimeInterval(_timeInterval, target: self, selector: "checkForScheduledNotifications", userInfo: nil, repeats: true)
        runLoop.addTimer(_timer, forMode: NSRunLoopCommonModes)
        runLoop.run()
    }
    
    @objc func checkForScheduledNotifications() {
        dispatch_sync(_notificationDispatchQueue) {
            var removedNotifications = [Notification]()
            for notification in self._queue {
                if notification.scheduledForDate <= NSDate() {
                    self.dispatch(notification)
                    removedNotifications.append(notification)
                }
            }
            if removedNotifications.count > 0 {
                for notification in removedNotifications {
                    self._queue = self._queue.filter { $0 != notification }
                }
            }
        }
    }
    
    func enqueueNotification(notification: Notification) {
        dispatch_sync(_notificationDispatchQueue) {
            self._queue.append(notification)
        }
    }

    func addHandler(handler: NotificationHandler) {
        dispatch_sync(_handlerDispatchQueue) {
            self._handlers.append(WeakHandler(handler))
        }
    }
    
    func removeHandler(handler: NotificationHandler) {
        dispatch_sync(_handlerDispatchQueue) {
            self._handlers = self._handlers.filter { weakHandler -> Bool in
                if let _handler = weakHandler.handler() {
                    return !_handler.isEqualToHandler(handler)
                }
                return false
            }
        }
    }
    
    func dispatch(notification: Notification) {
        dispatch_sync(_handlerDispatchQueue) {
            for (index, weakHandler) in self._handlers.enumerate() {
                if let handler = weakHandler.handler() {
                    if handler.canHandle(notification) {
                        dispatch_async(dispatch_get_main_queue()) {
                            handler.handle(notification)
                        }
                    }
                } else {
                    self._handlers.removeAtIndex(index)
                }
            }
        }
    }
}
