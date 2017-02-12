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

public func + (date: Date, timeInterval: TimeInterval) -> Date {
    return date.addingTimeInterval(timeInterval)
}

public extension TimeInterval {
    var second: TimeInterval {
        return seconds
    }
    
    var seconds: TimeInterval {
        return self
    }
    
    var minute: TimeInterval {
        return minutes
    }
    
    var minutes: TimeInterval {
        let minutesInADay = 1_440 as TimeInterval
        return self * minutesInADay
    }
    
    var day: TimeInterval {
        return days
    }
    
    var days: TimeInterval {
        let secondsInADay = 86_400 as TimeInterval
        return self * secondsInADay
    }
    
    var fromNow: Date {
        let timeInterval = self
        return Date().addingTimeInterval(timeInterval)
    }
    
    func from(_ date: Date) -> Date {
        let timeInterval = self
        return date.addingTimeInterval(timeInterval)
    }
    
    var ago: Date {
        let timeInterval = self
        return Date().addingTimeInterval(-timeInterval)
    }
}

open class NotificationQueue: Collection {
    
    public static var shared = NotificationQueue(timeInterval: 0.1)
    
    fileprivate var _timer: Timer!
    fileprivate var _timeInterval: TimeInterval
    fileprivate var _queue = [Notification]()
    fileprivate var _handlers = [WeakHandler]()
    fileprivate let _handlerDispatchQueue = DispatchQueue(label: "NotificationQueue.SynchronousHandlerDispatchQueue", attributes: [])
    fileprivate let _notificationDispatchQueue = DispatchQueue(label: "NotificationQueue.SynchronousNotificationDispatchQueue", attributes: [])
    
    public typealias Index = Int
    public var startIndex: Index {
        return 0
    }
    public var endIndex: Index {
        return _queue.endIndex
    }
    public func index(after i: Int) -> Int {
        guard i != endIndex else {
            fatalError("Cannot increment endIndex")
        }
        return i + 1
    }
    public var count: Int {
        return _queue.count
    }
    public var isEmpty: Bool {
        return _queue.isEmpty
    }
    
    public subscript(_i: Index) -> Notification {
        get {
            let notification = _queue[_i]
            return notification
        }
        set(newValue) {
            if !_queue.contains(newValue) {
                _queue.insert(newValue, at: _i)
            }
        }
    }
    
    public func makeIterator() -> AnyIterator<Notification> {
        var notificationGenerator = _queue.makeIterator()
        return AnyIterator {
            if let notification = notificationGenerator.next() {
                return notification
            }
            return nil
        }
    }
    
    public init(timeInterval: TimeInterval) {
        _timeInterval = timeInterval
        Thread.detachNewThreadSelector(#selector(NotificationQueue.createTimer), toTarget: self, with: nil)
    }
    
    @objc fileprivate func createTimer() {
        Thread.current.name = "NotificationQueueTimerThread"
        let runLoop = RunLoop.current
        _timer = Timer.scheduledTimer(timeInterval: _timeInterval, target: self, selector: #selector(NotificationQueue.checkForScheduledNotifications), userInfo: nil, repeats: true)
        runLoop.add(_timer, forMode: .commonModes)
        runLoop.run()
    }
    
    @objc func checkForScheduledNotifications() {
        _notificationDispatchQueue.sync {
            var removedNotifications = [Notification]()
            for notification in self._queue {
                if notification.scheduledForDate <= Date() {
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
    
    fileprivate func dispatch(_ notification: Notification) {
        _handlerDispatchQueue.sync {
            self._handlers = self._handlers.filter { $0.handler != nil }
            for weakHandler in self._handlers {
                guard let handler = weakHandler.handler else {
                    return
                }
                
                guard handler.canHandle(notification) else {
                    return
                }
                
                DispatchQueue.main.async {
                    handler.handle(notification)
                }
            }
        }
    }
    
    public func enqueue(_ notification: Notification) {
        _notificationDispatchQueue.sync {
            self._queue.append(notification)
        }
    }

    public func addHandler(_ handler: NotificationHandler) {
        _handlerDispatchQueue.sync {
            self._handlers.append(WeakHandler(handler))
        }
    }
    
    open func removeHandler(_ handler: NotificationHandler) {
        _handlerDispatchQueue.sync {
            self._handlers = self._handlers.filter { weakHandler -> Bool in
                guard let _handler = weakHandler.handler else {
                    return false
                }
                
                return !_handler.isEqualToHandler(handler)
            }
        }
    }
    
}
