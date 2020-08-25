//
//  NotificationHandler.swift
//  Ometria
//
//  Created by Cata on 7/31/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UserNotifications

open class NotificationHandler {
    
    func handleReceivedNotification(_ notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Ometria.sharedInstance().trackNotificationReceivedEvent(notificationId: "sample id (replace this in code)")
        completionHandler([])
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Ometria.sharedInstance().trackNotificationInteractedEvent(notificationId: "sample id (replace this in code)")
        completionHandler()
    }
    
    func processDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] (notifications) in
            let lastProcessedDate = OmetriaDefaults.notificationProcessDate
            let newNotifications = notifications.filter({$0.date > lastProcessedDate})
            OmetriaDefaults.notificationProcessDate = Date()
            newNotifications.forEach({
                self?.handleReceivedNotification($0, withCompletionHandler: {_ in })
            })
        }
    }
}
