//
//  NotificationHandler.swift
//  Ometria
//
//  Created by Cata on 7/31/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UserNotifications

/**
 A protocol that allows you to control what happens when a user interacts with an Ometria originated push notification
 */
public protocol OmetriaNotificationInteractionDelegate: AnyObject {
    /**
     Allows you to handle the outcome when a user interacts with an Ometria push notifications that has a valid deeplink url in the payload
     
     - Parameter deepLink: the processed url string that was received in the interacted notification payload
     */
    func handleDeepLinkInteraction(_ deepLink: URL)
}

class NotificationHandler {
    weak var interactionDelegate: OmetriaNotificationInteractionDelegate?
    
    func handleReceivedNotification(_ notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let notificationBody = parseNotificationContent(notification.request.content) {
            Ometria.sharedInstance().trackNotificationReceivedEvent(context: notificationBody.context)
        }
        completionHandler([])
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let notificationBody = parseNotificationContent(response.notification.request.content) {
            Ometria.sharedInstance().trackNotificationInteractedEvent(context: notificationBody.context)
            if let urlString = notificationBody.deepLinkActionURL {
                if let url = URL(string: urlString) {
                    interactionDelegate?.handleDeepLinkInteraction(url)
                    completionHandler()
                } else {
                    Logger.error(message: "The URL provided in the notification is invalid: \(urlString)", category: .push)
                }
            }
        }
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
    
    func parseNotificationContent(_ content: UNNotificationContent) -> OmetriaNotificationBody? {
        let info = content.userInfo
        
        guard let aps = info["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let ometriaContent = alert["ometria"] as? [String: Any] else {
            return nil
        }
        
        do {
            let notificationBody = try OmetriaNotificationBody(dictionary: ometriaContent)
            
            return notificationBody
        } catch let error as OmetriaError {
            Logger.error(message: error.localizedDescription)
            Ometria.sharedInstance().trackErrorOccuredEvent(error: error)
            
            return nil
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
            case .ephemeral:
                if lastKnownStatus != .ephemeral {
                    Logger.verbose(message: "Notification authorization status changed to 'ephemeral'.", category: .push)
                    Ometria.sharedInstance().trackPermissionsUpdateEvent(hasPermissions: true)
                }
                
            @unknown default:
                Logger.verbose(message: "Notification authorization status changed to an unknown status.", category: .push)
            }
            
            OmetriaDefaults.lastKnownNotificationAuthorizationStatus = settings.authorizationStatus.rawValue
        })
    }
    
    func verifyPushNotificationAuthorizationStatus(completion: (_ hasAuthorization:Bool)->()) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied, .notDetermined:
                completion(false)
            }
        })
    }
}
