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
        var installationID = OmetriaDefaults.installationID
        if installationID == nil {
            installationID = generateInstallationID()
            OmetriaDefaults.installationID = installationID
        }
//        trackEvent(type: .installApplication, value: installmentID!)
    }
    
  
    private func generateInstallationID() -> String {
        let installationID = UUID().uuidString
        return installationID
    }
    
    // MARK: - Event Tracking
    
    private func trackEvent(_ event: OmetriaEvent) {
        Logger.info(message: "Track Event \(event)", category: LogCategory.events)
    }
    
    private func trackEvent(type: OmetriaEventType, data: [String: Codable] = [:]) {
        let event = OmetriaEvent(type: type, data: data)
        trackEvent(event)
    }
    
    // MARK: Application Related Events
    
    func trackAppInstalledEvent() {
        trackEvent(type: .appInstalled)
    }
    
    func trackAppLaunchedEvent() {
        trackEvent(type: .appLaunched)
    }
    
    func trackAppBackgroundedEvent() {
        trackEvent(type: .appBackgrounded)
    }
    
    func trackAppForegroundedEvent() {
        trackEvent(type: .appForegrounded)
    }
    
    open func trackScreenViewedEvent(screenName: String, additionalInfo:[String: Codable] = [:]) {
        var data = additionalInfo
        data["page"] = screenName
        trackEvent(type: .screenViewed, data: data)
    }
    
    open func trackProfileIdentifiedEvent(email: String) {
        trackEvent(type: .profileIdentified, data: ["email": email])
    }
    
    open func trackProfileIdentifiedEvent(customerId: String) {
        trackEvent(type: .profileIdentified, data: ["customerId": customerId])
    }
    
    open func trackProfileDeidentifiedEvent() {
        trackEvent(type: .profileDeidentified)
    }
    
    // MARK: Product Related Events
    
    open func trackProductViewedEvent(productId: String) {
        trackEvent(type: .productViewed, data: ["productId": productId])
    }
    
    open func trackProductCategoryViewedEvent(category: String) {
        trackEvent(type: .productCategoryViewed, data: ["category": category])
    }
    
    open func trackWishlistAddedToEvent(productId: String) {
        trackEvent(type: .wishlistAddedTo, data: ["productId": productId])
    }
    
    open func trackWishlistRemovedFromEvent(productId: String) {
        trackEvent(type: .wishlistRemovedFrom, data: ["productId": productId])
    }
    
    open func trackBasketViewedEvent() {
        trackEvent(type: .basketViewed)
    }
    
    open func trackBasketUpdatedEvent(basket: OmetriaBasket) {
        trackEvent(type: .basketUpdated, data: ["basket": basket])
    }
    
    open func trackOrderCompletedEvent(orderId: String, basket: OmetriaBasket) {
        trackEvent(type: .orderCompleted, data: ["orderId": orderId,
                                                 "basket": basket])
    }
    
    // MARK: Notification Related Events
    
    open func trackPushTokenRefreshedEvent(pushToken: String) {
        trackEvent(type: .pushTokenRefreshed, data: ["pushToken": pushToken])
    }
    
    open func trackNotificationReceivedEvent(notificationId: String) {
        trackEvent(type: .notificationReceived, data: ["notificationId": notificationId])
    }
    
    open func trackNotificationInteractedEvent(notificationId: String) {
        trackEvent(type: .notificationInteracted, data: ["notificationId": notificationId])
    }
    
    // MARK: Other Events
    
    open func trackDeepLinkOpenedEvent(link: String, screenName: String) {
        trackEvent(type: .deepLinkOpened, data: ["link": link,
                                                 "page": screenName])
    }
    
    open func trackCustomEvent(customEventType: String, additionalInfo: [String: Codable]) {
        var data = additionalInfo
        data["customEventType"] = customEventType
        trackEvent(type: .custom(customType: customEventType), data: data)
    }
    
    open func flush() {
        // TODO: Implement Method
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
