//
//  AppDelegate.swift
//  OmetriaSample
//
//  Created by Cata on 7/13/20.
//  Copyright © 2020 Ometria. All rights reserved.
//

import UIKit
import FirebaseMessaging
import FirebaseCore
import Ometria
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, OmetriaNotificationInteractionDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize the Ometria SDK here.
        // Make sure to replace your token in the intialization method
        Ometria.initialize(apiToken: "YOUR_API_TOKEN_HERE")
        
        // Enable logs in order to see if there are any problems encountered
        Ometria.sharedInstance().isLoggingEnabled = true
        
        // Set the notificationInteractionDelegate in order to provide actions for
        // notifications that contain a deeplink URL.
        // The default functionality when you don't assign a delegate is opening urls in a browser
        Ometria.sharedInstance().notificationInteractionDelegate = self
        
        // Configure Firebase. Make sure you replace the GoogleService-Info.plist file
        // with the one from your project.
        FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.min)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        
        configurePushNotifications()
        
        window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        window?.makeKeyAndVisible()
        return true
    }

    // MARK: Push Notifications
    
    func configurePushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) {
            [weak self] (granted, error) in
            
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard #available(iOS 12.0, *), settings.authorizationStatus == .provisional ||
                settings.authorizationStatus == .authorized else {
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Reaching Did register for remote notifications")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Reaching Did receive notification response")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Reaching Will present notification")
        completionHandler([.alert, .sound])
    }
    
    // MARK: - OmetriaNotificationInteractionDelegate
    
    // This method will be called each time the user interacts with a notification from Ometria
    // which contains a deepLinkURL. Write your own custom code in order to
    // properly redirect the app to the screen that should be displayed.
    // If you do not implement this method at all, the default behaviour is to open the browser and log a DeepLinkOpened Event as you can see below.
    func handleDeepLinkInteraction(_ deepLink: URL) {
        if UIApplication.shared.canOpenURL(deepLink) == true {
            UIApplication.shared.open(deepLink)
            Ometria.sharedInstance().trackDeepLinkOpenedEvent(link: deepLink.absoluteString, screenName: "Safari")
        } else {
            print("The provided deeplink URL (\(deepLink.absoluteString) cannot be processed.")
        }
    }
}
