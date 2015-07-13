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
    
    private let lock = NSLock()
    private var timer: NSTimer!
    private var timeInterval: NSTimeInterval
    private var queue = [Notification]()
    private var handlers = [WeakHandler]()
    
    internal typealias Index = Int
    internal var startIndex: Index { return 0 }
    internal var endIndex: Index { return queue.endIndex }

    var count: Int { return queue.count }
    var isEmpty: Bool { return queue.isEmpty }
    
    subscript (_i: Index) -> Notification {
        get {
            let notification = queue[_i]
            return notification
        }
        set(newValue) {
            if !contains(queue, newValue) {
                queue.insert(newValue, atIndex: _i)
            }
        }
    }
    
    func generate() -> GeneratorOf<Notification> {
        var notificationGenerator = queue.generate()
        return GeneratorOf {
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
        self.timeInterval = timeInterval
        NSThread.detachNewThreadSelector("createTimer", toTarget: self, withObject: nil)
    }
    
    @objc private func createTimer() {
        NSThread.currentThread().name = "NotificationQueueTimerThread"
        let runLoop = NSRunLoop.currentRunLoop()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: "checkForScheduledNotifications", userInfo: nil, repeats: true)
        runLoop.addTimer(self.timer, forMode: NSRunLoopCommonModes)
        runLoop.run()
    }
    
    @objc func checkForScheduledNotifications() {
        if lock.tryLock() {
            var removedNotifications = [Notification]()
            for (index, notification) in enumerate(queue) {
                if notification.scheduledForDate <= NSDate() {
                    dispatch(notification)
                    removedNotifications.append(notification)
                }
            }
            if removedNotifications.count > 0 {
                for (_, notification) in enumerate(removedNotifications) {
                    queue = queue.filter { $0 != notification }
                }
            }
            lock.unlock()
        }
    }
    
    func enqueueNotification(notification: Notification) {
        lock.lock()
        queue.append(notification)
        lock.unlock()
    }

    func addHandler(handler: NotificationHandler) {
        handlers.append(WeakHandler(handler))
    }
    
    func removeHandler(handler: NotificationHandler) {
        handlers = handlers.filter { weakHandler -> Bool in
            if let _handler = weakHandler.handler() {
                return !_handler.isEqualToHandler(handler)
            }
            return false
        }
    }
    
    func dispatch(notification: Notification) {
        for (index, weakHandler) in enumerate(handlers) {
            if let handler = weakHandler.handler() {
                if handler.canHandle(notification) {
                    dispatch_async(dispatch_get_main_queue()) {
                        handler.handle(notification)
                    }
                }
            } else {
                handlers.removeAtIndex(index)
            }
        }
    }
}
