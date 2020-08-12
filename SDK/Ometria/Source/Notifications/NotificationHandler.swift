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
//        Ometria.sharedInstance().trackEvent(type: .receivedNotification, value: notification.request.content.title)
        completionHandler([.sound, .alert])
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        Ometria.sharedInstance().trackEvent(type: .receivedNotification, value: response.actionIdentifier)
        completionHandler()
    }
}
