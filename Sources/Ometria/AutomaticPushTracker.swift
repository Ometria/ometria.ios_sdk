//
//  PushNotificationTracker.swift
//  Ometria
//
//  Created by Cata on 7/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit
import FirebaseMessaging

@available(iOS 10.0, *)
extension UNUserNotificationCenter {
    func addDelegateObserver(observer: AutomaticPushTracker) {
        addObserver(observer, forKeyPath: #keyPath(delegate), options: [.old, .new], context: nil)
    }
    
    func removeDelegateObserver(observer: AutomaticPushTracker) {
        removeObserver(observer, forKeyPath: #keyPath(delegate))
    }
}

open class AutomaticPushTracker: NSObject {
    
    open var isRunning = false
    open var isDelegateObserverAdded = false

    @available(iOSApplicationExtension, unavailable)
    open func startTracking() {
        guard !isRunning else {
            return
        }
        
        guard !Bundle.main.bundlePath.hasSuffix(".appex") else {
            return
        }
        
        isRunning = true
        swizzleDidRegisterForRemoteNotificationsWithDeviceToken()
        swizzleDidFailToRegisterForRemoteNotificationsWithError()
        swizzleDidReceiveRemoteNotification()
        swizzleDidReceiveSilentNotification()
        
        NotificationCenter.default.addObserver(self, selector: #selector(firebaseTokenDidRefresh(notification:)), name: Notification.Name.MessagingRegistrationTokenRefreshed, object: nil)
    }

    @available(iOSApplicationExtension, unavailable)
    open func stopTracking() {
        guard isRunning else {
            return
        }
        
        isRunning = false
        unswizzleDidReceiveSilentNotification()
        unswizzleDidReceiveRemoteNotification()
        unswizzleDidFailToRegisterForRemoteNotificationsWithError()
        unswizzleDidRegisterForRemoteNotificationsWithDeviceToken()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        if #available(iOS 10.0, *), isDelegateObserverAdded {
            UNUserNotificationCenter.current().removeDelegateObserver(observer: self)
        }
    }

    @available(iOSApplicationExtension, unavailable)
    private func swizzleDidRegisterForRemoteNotificationsWithDeviceToken() {
        Logger.verbose(message: "Swizzle did register for remote notifications")
        let newSelector = #selector(UIResponder.om_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let delegateClass: AnyClass! = object_getClass(UIApplication.shared.delegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        Swizzler.swizzleSelector(originalSelector,
                                 withSelector: newSelector,
                                 for: delegateClass,
                                 name: "OmetriaRegisterForRemoteNotifications") { (_, _, _, _) in
                                    Logger.verbose(message: "Application did register for remote notifications")
        }
    }

    @available(iOSApplicationExtension, unavailable)
    private func unswizzleDidRegisterForRemoteNotificationsWithDeviceToken() {
        let delegateClass: AnyClass! = object_getClass(UIApplication.shared.delegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        Swizzler.unswizzleSelector(originalSelector, aClass: delegateClass)
    }

    @available(iOSApplicationExtension, unavailable)
    private func swizzleDidFailToRegisterForRemoteNotificationsWithError() {
        Logger.verbose(message: "Swizzle did fail to register for remote notifications")
        let newSelector = #selector(UIResponder.om_application(_:didFailToRegisterForRemoteNotificationsWithError:))
        let delegateClass: AnyClass! = object_getClass(UIApplication.shared.delegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        Swizzler.swizzleSelector(originalSelector,
                                 withSelector: newSelector,
                                 for: delegateClass,
                                 name: "OmetriaDidFailToRegisterForRemoteNotificationsWithError") { (_, _, _, _) in
                                    Logger.verbose(message: "Application did fail to register for remote notifications")
        }
    }

    @available(iOSApplicationExtension, unavailable)
    private func unswizzleDidFailToRegisterForRemoteNotificationsWithError() {
        let delegateClass: AnyClass! = object_getClass(UIApplication.shared.delegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        Swizzler.unswizzleSelector(originalSelector, aClass: delegateClass)
    }

    @available(iOSApplicationExtension, unavailable)
    private func swizzleDidReceiveSilentNotification() {
        Logger.verbose(message: "Swizzle application:didReceiveRemoteNotification:fetchCompletionHandler:")
        let newSelector = #selector(UIResponder.om_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        let delegateClass: AnyClass! = object_getClass(UIApplication.shared.delegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        Swizzler.swizzleSelector(originalSelector,
                                 withSelector: newSelector,
                                 for: delegateClass,
                                 name: "OmetriaDidReceiveSilentNotification") { (_, _, _, _) in
                                    Logger.debug(message: "Application didReceiveSilentNotification")
        }
    }

    @available(iOSApplicationExtension, unavailable)
    private func unswizzleDidReceiveSilentNotification() {
        let delegateClass: AnyClass! = object_getClass(UIApplication.shared.delegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        Swizzler.unswizzleSelector(originalSelector, aClass: delegateClass)
    }
    
    private func swizzleDidReceiveRemoteNotification() {
        var newClass: AnyClass?
        
        guard #available(iOS 10.0, *) else {
            return
        }
        
        if let UNDelegate = UNUserNotificationCenter.current().delegate {
            newClass = type(of: UNDelegate)
        } else {
            UNUserNotificationCenter.current().addDelegateObserver(observer: self)
            isDelegateObserverAdded = true
            return
        }
        
        if let newClass = newClass {
            let newSelector = #selector(NSObject.om_userNotificationCenter(_:newDidReceive:withCompletionHandler:))
            let originalSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
            
            Swizzler.swizzleSelector(originalSelector,
                                     withSelector: newSelector,
                                     for: newClass,
                                     name: "OmetriaDidReceiveRemoteNotification") { (_, _, _, _) in
                                        Logger.debug(message: "Application didReceiveRemoteNotificationResponse")
            }
            
            let newWillPresentSelector = #selector(NSObject.om_userNotificationCenter(_:newWillPresent:withCompletionHandler:))
            let originalWillPresentSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))
            
            Swizzler.swizzleSelector(originalWillPresentSelector,
                                     withSelector: newWillPresentSelector,
                                     for: newClass,
                                     name: "OmetriaWillPresentRemoteNotification") { (_, _, _, _) in
                                        Logger.debug(message: "Application willPresentRemoteNotification")
            }
        }
    }
    
    private func unswizzleDidReceiveRemoteNotification() {
        guard #available(iOS 10.0, *) else {
            return
        }
        
        var newClass: AnyClass?
        
        if let UNDelegate = UNUserNotificationCenter.current().delegate {
            newClass = type(of: UNDelegate)
        } else {
            return
        }
        
        let originalSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        let originalWillPresentSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))
        
        Swizzler.unswizzleSelector(originalSelector, aClass: newClass!)
        Swizzler.unswizzleSelector(originalWillPresentSelector, aClass: newClass!)
    }
    
    // MARK: - Firebase Token
    @objc private func firebaseTokenDidRefresh(notification: Notification) {
        if let token = Messaging.messaging().fcmToken { // implemented like this to support Firebase v7.x
            processFirebaseToken(token)
        } else { // this code works for Firebase > v8.x
            Messaging.messaging().token { [weak self] token, error in
                if let error = error {
                    Logger.error(message: error.localizedDescription)
                }
                if let token = token {
                    self?.processFirebaseToken(token)
                } else {
                    Logger.error(message: "Invalid push token retrieved from Firebase")
                }
            }
        }
    }
    
    private func processFirebaseToken(_ token: String) {
        OmetriaDefaults.fcmToken = token
        Logger.debug(message: "Application firebase token automatically captured:\n\(String(describing: token))")
        Ometria.sharedInstance().trackPushTokenRefreshedEvent(pushToken: token)
    }
    
    // MARK: - Observer
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if #available(iOS 10.0, *), keyPath == "delegate" {
            swizzleDidReceiveRemoteNotification()
        }
    }
}

// MARK: - UIResponder swizzled method implementations

extension UIResponder {
    @objc func om_application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Logger.debug(message: "Did register for remote notifications with device token: \(deviceToken)")
        
        
        guard let applicationDelegate = Ometria.sharedUIApplication()?.delegate else {
            return
        }
        
        let aClass: AnyClass! = object_getClass(applicationDelegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        if let swizzle = Swizzler.getSwizzle(for: originalSelector, in: aClass) {
            typealias MyCFunction = @convention(c) (AnyObject, Selector, UIApplication, Data) -> Void
            let originalImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            
            originalImplementation(applicationDelegate, originalSelector, application, deviceToken)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, application, deviceToken as AnyObject)
            }
        }
        
        Ometria.sharedInstance().application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    @objc func om_application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.debug(message: "Did fail to register for remote notifications with error: \(error.localizedDescription)")
        
        guard let applicationDelegate = Ometria.sharedUIApplication()?.delegate else {
            return
        }
        
        let aClass: AnyClass! = object_getClass(applicationDelegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        if let swizzle = Swizzler.getSwizzle(for: originalSelector, in: aClass) {
            typealias MyCFunction = @convention(c) (AnyObject, Selector, UIApplication, Error) -> Void
            let originalImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            
            originalImplementation(applicationDelegate, originalSelector, application, error)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, application, error as AnyObject)
            }
        }
        
        Ometria.sharedInstance().application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    @objc func om_application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Logger.debug(message: "Did receive remote notification with user info: \(userInfo)")
        
        guard let applicationDelegate = Ometria.sharedUIApplication()?.delegate else {
            return
        }
        
        let aClass: AnyClass! = object_getClass(applicationDelegate)
        let originalSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        if let swizzle = Swizzler.getSwizzle(for: originalSelector, in: aClass) {
            typealias MyCFunction = @convention(c) (AnyObject, Selector, UIApplication, [AnyHashable : Any], ((UIBackgroundFetchResult) -> Void)) -> Void
            let originalImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            
            originalImplementation(applicationDelegate, originalSelector, application, userInfo, completionHandler)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, application, userInfo as AnyObject)
            }
        }
        
        Ometria.sharedInstance().application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
}

// MARK: - UserNotificationCenter delegate swizzled methods

@available(iOS 10.0, *)
extension NSObject {
    @objc func om_userNotificationCenter(_ center: UNUserNotificationCenter,
                                         newDidReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        let originalSelector = NSSelectorFromString("userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:")
        
        if let swizzle = Swizzler.getSwizzle(for: originalSelector, in: type(of: self)) {
            typealias MyCFunction = @convention(c) (AnyObject, Selector, UNUserNotificationCenter, UNNotificationResponse, @escaping () -> Void) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            curriedImplementation(self, originalSelector, center, response, completionHandler)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, center as AnyObject?, response.notification.request.content.userInfo as AnyObject?)
            }
        }
        
        Ometria.sharedInstance().userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    @objc func om_userNotificationCenter(_ center: UNUserNotificationCenter,
                                         newWillPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let originalSelector = NSSelectorFromString("userNotificationCenter:willPresentNotification:withCompletionHandler:")
        
        if let swizzle = Swizzler.getSwizzle(for: originalSelector, in: type(of: self)) {
            typealias MyCFunction = @convention(c) (AnyObject, Selector, UNUserNotificationCenter, UNNotification, @escaping (UNNotificationPresentationOptions) -> Void) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            curriedImplementation(self, originalSelector, center, notification, completionHandler)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, center as AnyObject?, notification.request.content.userInfo as AnyObject?)
            }
        }
        
        Ometria.sharedInstance().userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }
}
