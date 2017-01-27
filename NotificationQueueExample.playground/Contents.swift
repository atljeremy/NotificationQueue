import UIKit
import NotificationQueueExample_Sources

//: ## NotificationQueue

//: Here's an example of creating a notification that should be displayed immediately, notice their is no "scheduledForDate" parameter
let notification = Notification(title: "Title", message: "Sub-title", style: .success)

//: Here's an example of creating a notification that should be displayed in 5 seconds
let delayedNotificaiton = Notification(scheduled: 5.seconds.fromNow, title: "Title", message: "Sub-title", style: .success)

//: Scheduling notification's is super easy, just pass them in to the "enqueueNotification:" function of the NotificationQueue
NotificationQueue.shared.enqueueNotification(notification)
NotificationQueue.shared.enqueueNotification(delayedNotificaiton)

class SomeViewController: UIViewController, NotificationHandler {
    
    func canHandle(_ notification: NotificationQueueExample_Sources.Notification) -> Bool {
        
        // Code to determine if the "notification" can be handled by this class instance
        // true = this class instance can and should handle the "notification"
        // false = this class instance can't and shouldn't handle the "notification"

        let alertIsShowing = self.presentedViewController is UIAlertController
        let isCurrentVisibleViewController = self.navigationController?.visibleViewController is SomeViewController
        if isCurrentVisibleViewController && !alertIsShowing {
            return true
        }
        return false
    }
    
    func handle(_ notification: NotificationQueueExample_Sources.Notification) {
        
        // Code to handle showing the "notificaiton"
        
        let alert = UIAlertController(title: notification.title, message: notification.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func isEqualToHandler(_ handler: NotificationHandler) -> Bool {
        
        // Code to determine if "handler" is equal to "self" (which should be a class instace that conforms to NotificationHandler)
        
        return (handler as? SomeViewController) == self
        
    }

}
