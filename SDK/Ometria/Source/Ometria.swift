//
//  Ometria.swift
//  Ometria
//
//  Created by Cata on 7/10/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

open class Ometria: NSObject, UNUserNotificationCenterDelegate {
    
    open var apiToken: String
    private var preferences: Preferences
    static var instance: Ometria?
    private let automaticPushTracker = AutomaticPushTracker()
    private let automaticLifecycleTracker = AutomaticLifecycleTracker()
    private let automaticScreenViewsTracker = AutomaticScreenViewsTracker()
    private let notificationHandler = NotificationHandler()
    
    @discardableResult
    open class func initialize(apiToken: String, preferences: Preferences = Preferences()) -> Ometria {
        let ometria = Ometria(apiToken: apiToken, preferences: preferences)
        instance = ometria
        return ometria
    }
    
    open class func sharedInstance() -> Ometria {
        guard instance != nil else {
            assert(false, "You are not allowed to call the sharedInstance() method before calling initialize(apiToken:preferences:).")
        }
        return instance!
    }
    
    init(apiToken: String, preferences: Preferences) {
        self.preferences = preferences
        self.apiToken = apiToken
        super.init()
        
        isLoggerEnabled = preferences.isLoggingEnabled
        // didSet not called from initializer. setLoggingEnabled is force called to remedy that.
        setLoggerEnabled(isLoggerEnabled)
        
        if preferences.automaticallyTrackNotifications {
            automaticPushTracker.startTracking()
        }
        if preferences.automaticallyTrackAppLifecycle {
            automaticLifecycleTracker.startTracking()
        }
        if preferences.automaticallyTrackScreenListing {
            automaticScreenViewsTracker.startTracking()
        }
        handleApplicationLaunch()
    }
    
    open var isLoggerEnabled: Bool = false {
        didSet {
            setLoggerEnabled(isLoggerEnabled)
        }
    }
    
    func setLoggerEnabled(_ enabled: Bool) {
        if enabled {
            Logger.enableLevel(.debug)
            Logger.enableLevel(.info)
            Logger.enableLevel(.warning)
            Logger.enableLevel(.error)

            Logger.debug(message: "Logger Enabled")
        } else {
            Logger.debug(message: "Logger Disabled")

            Logger.disableLevel(.debug)
            Logger.disableLevel(.info)
            Logger.disableLevel(.warning)
            Logger.disableLevel(.error)
        }
    }
    
    // MARK: - Application launch
    
    private func handleApplicationLaunch() {
        OmetriaDefaults.lastLaunchDate = Date()
        if OmetriaDefaults.isFirstLaunch {
            handleAppInstall()
        }
        
//        trackEvent(type: .launchApplication, value: nil)
    }
    
    private func handleAppInstall() {
        OmetriaDefaults.isFirstLaunch = false
        var installmentID = OmetriaDefaults.installmentID
        if installmentID == nil {
            installmentID = generateInstallmentID()
            OmetriaDefaults.installmentID = installmentID
        }
//        trackEvent(type: .installApplication, value: installmentID!)
    }
    
  
    private func generateInstallmentID() -> String {
        let installmentID = UUID().uuidString
        return installmentID
    }
    
    // MARK: - Event Tracking
    
    private func trackEvent(_ event: OmetriaEvent) {
        Logger.info(message: "Track Event \(event)", category: LogCategory.events)
    }
    
    private func trackEvent(type: OmetriaEventType, data: [String: Codable]) {
        let event = OmetriaEvent(type: type, data: data)
        trackEvent(event)
    }
    
    open func trackCustomEvent(customEventType: String, data: [String: Codable]) {
        trackEvent(type: .custom(customType: customEventType), data: data)
    }
    
    
    // MARK: - Push notifications
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        notificationHandler.handleNotificationResponse(response, withCompletionHandler: completionHandler)
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        notificationHandler.handleReceivedNotification(notification, withCompletionHandler: completionHandler)
    }
    
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    }
    
}
