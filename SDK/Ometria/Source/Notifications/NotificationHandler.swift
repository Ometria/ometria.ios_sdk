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
        if let notificationBody = validateAndRetrieveNotificationContent(notification: notification) {
            Ometria.sharedInstance().trackNotificationReceivedEvent(context: notificationBody.context)
        }
        completionHandler([])
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let notificationBody = validateAndRetrieveNotificationContent(notification: response.notification) {
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
    
    func validateAndRetrieveNotificationContent(notification: UNNotification) -> OmetriaNotificationBody? {
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
    
    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            let lastKnownStatusInt = OmetriaDefaults.lastKnownNotificationAuthorizationStatus
            let lastKnownStatus = UNAuthorizationStatus(rawValue: lastKnownStatusInt)
            
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                if lastKnownStatus != .authorized,
                    #available(iOS 12.0, *), lastKnownStatus != .provisional {
                    Logger.verbose(message: "Notification authorization status changed to 'authorized'.", category: .push)
                    Ometria.sharedInstance().trackPermissionsUpdateEvent(hasPermissions: true)
                }
                
            case .denied:
                if lastKnownStatus != .denied {
                    Logger.verbose(message: "Notification authorization status changed to 'denied'.", category: .push)
                    Ometria.sharedInstance().trackPermissionsUpdateEvent(hasPermissions: false)
                }
            case .notDetermined:
                if lastKnownStatus != .notDetermined {
                    Logger.verbose(message: "Notification authorization status changed to 'not determined'.", category: .push)
                    Ometria.sharedInstance().trackPermissionsUpdateEvent(hasPermissions: false)
                }
            @unknown default:
                Logger.verbose(message: "Notification authorization status changed to an unknown status.", category: .push)
            }
            
            OmetriaDefaults.lastKnownNotificationAuthorizationStatus = settings.authorizationStatus.rawValue
        })
    }
}
