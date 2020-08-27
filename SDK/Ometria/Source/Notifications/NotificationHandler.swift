//
//  NotificationHandler.swift
//  Ometria
//
//  Created by Cata on 7/31/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UserNotifications


class NotificationHandler {
    
    func handleReceivedNotification(_ notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let notificationBody = retrieveContext(notification: notification) {
            Ometria.sharedInstance().trackNotificationReceivedEvent(context: notificationBody.context)
        }
        completionHandler([])
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let notificationBody = retrieveContext(notification: response.notification) {
            Ometria.sharedInstance().trackNotificationInteractedEvent(context: notificationBody.context)
        }
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
    
    func retrieveContext(notification: UNNotification) -> OmetriaNotificationBody? {
        let info = notification.request.content.userInfo
        guard let aps = info["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let ometriaContent = alert["ometria"] as? [String: Any] else {
            return nil
        }
        do {
            let notificationBody = try OmetriaNotificationBody(dictionary: ometriaContent)
            return notificationBody
        } catch {
            Logger.error(message: error.localizedDescription)
            return nil
        }
    }
}
