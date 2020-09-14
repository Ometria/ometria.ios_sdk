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
        Ometria.initialize(apiToken: "YOUR_API_TOKEN_HERE")
        Ometria.sharedInstance().isLoggingEnabled = true
        Ometria.sharedInstance().notificationInteractionDelegate = self
        
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
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("Reaching continue userActivity")
        return true
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
    
    func handleDeepLinkInteraction(_ deepLink: URL) {
        print("url: \(deepLink)")
    }
}
