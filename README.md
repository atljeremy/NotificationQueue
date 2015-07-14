# NotificationQueue

Here's an example of creating a notification that should be displayed immediately, notice their is no "scheduledForDate" parameter
```swift
let notification = Notification("Title", "Sub-title", .Success)
```

Here's an example of creating a notification that should be displayed in 5 seconds
```swift
let delayedNotificaiton = Notification(scheduledForDate: 5.seconds.fromNow, "Title", "Sub-title", .Success)
```

Scheduling notification's is super easy, just pass them in to the "enqueueNotification:" function of the NotificationQueue
```swift
NotificationQueue.sharedQueue().enqueueNotification(notification)
NotificationQueue.sharedQueue().enqueueNotification(delayedNotificaiton)
```

```swift
class SomeViewController: UIViewController, NotificationHandler {
    
    func canHandle(notification: Notification) -> Bool {
        
        // Code to determine if the "notification" can be handled by this class instance
        // true = this class instance can and should handle the "notification"
        // false = this class instance can't and shouldn't handle the "notification"
        
        return true
    }
    
    func handle(notification: Notification) {
        
        // Code to handle showing the "notificaiton"
        
        var alert = UIAlertController(title: notification.title, message: notification.message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func isEqualToHandler(handler: NotificationHandler) -> Bool {
        
        // Code to determine if "handler" is equal to "self" (which should be a class instace which conforms to NotificationHandler)
        
        return (handler as? SomeViewController) == self
        
    }

}
```
