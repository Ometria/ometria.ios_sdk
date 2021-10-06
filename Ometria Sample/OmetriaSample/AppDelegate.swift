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
    
    // Note, this is now deprecated and will be removed in a future version. Use 'handleOmetriaNotificationInteraction' instead.
    func handleDeepLinkInteraction(_ deepLink: URL) {
    }
    
    // This method will be called each time the user interacts with a notification from Ometria.
    // Write your own custom code in order to
    // properly redirect the app to the screen that should be displayed.
    // If you do not implement this interface at all, the default behaviour is to open the browser and log a DeepLinkOpened Event as you can see below.
    func handleOmetriaNotificationInteraction(_ notification: OmetriaNotification) {
        if let urlString = notification.deepLinkActionUrl, let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) == true {
                UIApplication.shared.open(url)
                Ometria.sharedInstance().trackDeepLinkOpenedEvent(link: urlString, screenName: "Safari")
            } else {
                print("The provided deeplink URL (\(urlString) cannot be processed.")
            }
        }
    }
    
    
    // MARK: - Universal Link Handling
    
    // This is the standard method to intercept user activities that the app is able to process.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL { // case where the user activity is generated by interacting with an url
            
            // Here you should check whether the link is one that can already be handled by the app.
            // If the link is identified as one coming from an Ometria campaign, you will be able to
            // get the final URL in your website by calling the following method.
            //
            // This is a straightforward implementation without any loading screens, but in the scenario where the users have slow data connectivity you might be waiting for a while until the redirect is obtained, so presenting a loading screen might be a good idea.
            Ometria.sharedInstance().processUniversalLink(url) { (url, error) in
                if let url = url {
                    let alert = UIAlertController(title: "Universal Link Processed", message: url.absoluteString, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    let urlAction = UIAlertAction(title: "Go To URL", style: .default) { (action) in
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                    alert.addAction(okAction)
                    alert.addAction(urlAction)
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }
            }
        }
        return true
    }
}
