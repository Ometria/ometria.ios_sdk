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
    private var config: OmetriaConfig
    static var instance: Ometria?
    private let automaticPushTracker = AutomaticPushTracker()
    private let automaticLifecycleTracker = AutomaticLifecycleTracker()
    private let automaticScreenViewsTracker = AutomaticScreenViewsTracker()
    private let notificationHandler = NotificationHandler()
    private let eventHandler: EventHandler
    
    @discardableResult
    open class func initialize(apiToken: String) -> Ometria {
        let ometria = Ometria(apiToken: apiToken, config: OmetriaConfig())
        instance = ometria
        ometria.handleApplicationLaunch()
        return ometria
    }
    
    open class func sharedInstance() -> Ometria {
        guard instance != nil else {
            assert(false, "You are not allowed to call the sharedInstance() method before calling initialize(apiToken:).")
        }
        return instance!
    }
    
    init(apiToken: String, config: OmetriaConfig) {
        self.config = config
        self.apiToken = apiToken
        self.eventHandler = EventHandler(flushLimit: config.flushLimit)
        super.init()
        
        isLoggingEnabled = config.isLoggingEnabled
        // didSet not called from initializer. setLoggingEnabled is force called to remedy that.
        setLoggerEnabled(isLoggingEnabled)
        
      
        if config.automaticallyTrackNotifications {
            automaticPushTracker.startTracking()
        }
        if config.automaticallyTrackAppLifecycle {
            automaticLifecycleTracker.startTracking()
        }
        if config.automaticallyTrackScreenListing {
            automaticScreenViewsTracker.startTracking()
        }
    }
    
    open var isLoggingEnabled: Bool = false {
        didSet {
            setLoggerEnabled(isLoggingEnabled)
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
        trackAppLaunchedEvent()
    }
    
    private func handleAppInstall() {
        OmetriaDefaults.isFirstLaunch = false
        resetAppInstallationId()
    }
    
    private func resetAppInstallationId() {
        let installationID = UUID().uuidString
        OmetriaDefaults.installationID = installationID
        trackAppInstalledEvent()
    }
    
    // MARK: - Event Tracking
    
    private func trackEvent(type: OmetriaEventType, data: [String: Any] = [:]) {
        eventHandler.processEvent(type: type, data: data)
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
        eventHandler.flushEvents()
    }
    
    func trackAppForegroundedEvent() {
        trackEvent(type: .appForegrounded)
        notificationHandler.checkNotificationSettings()
        notificationHandler.processDeliveredNotifications()
        eventHandler.flushEvents()
    }
    
    open func trackHomeScreenViewedEvent() {
        trackEvent(type: .homeScreenViewed)
    }
    
    open func trackScreenViewedEvent(screenName: String, additionalInfo:[String: Any] = [:]) {
        var data = additionalInfo
        data["page"] = screenName
        trackEvent(type: .screenViewedExplicit, data: data)
    }
    
    func trackScreenViewedAutomaticEvent(screenName: String) {
        trackEvent(type: .screenViewedAutomatic, data: ["page": screenName])
    }
    
    open func trackProfileIdentifiedEvent(email: String) {
        trackEvent(type: .profileIdentified, data: ["email": email])
    }
    
    open func trackProfileIdentifiedEvent(customerId: String) {
        trackEvent(type: .profileIdentified, data: ["customerId": customerId])
    }
    
    private func trackProfileIdentifiedEvent(data: [String: Any]) {
        trackEvent(type: .profileIdentified, data: data)
        if let fcmToken = OmetriaDefaults.fcmToken {
            trackPushTokenRefreshedEvent(pushToken: fcmToken)
        }
    }
    
    open func trackProfileDeidentifiedEvent() {
        trackEvent(type: .profileDeidentified)
        resetAppInstallationId()
    }
    
    // MARK: Product Related Events
    
    open func trackProductViewedEvent(productId: String) {
        trackEvent(type: .productViewed, data: ["productId": productId])
    }
    
    open func trackProductListingViewedEvent() {
        trackEvent(type: .productListingViewed)
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
        do {
            let serializedBasket = try basket.jsonObject()
            trackEvent(type: .basketUpdated, data: ["basket": serializedBasket])
        } catch {
            Logger.error(message: "Failed to track \(OmetriaEventType.basketUpdated.rawValue) event with error: \(error)", category: .events)
        }
    }
    
    open func trackOrderCompletedEvent(orderId: String, basket: OmetriaBasket) {
        do {
            let serializedBasket = try basket.jsonObject()
            trackEvent(type: .orderCompleted, data: ["orderId": orderId,
                                                     "basket": serializedBasket])
        } catch {
            Logger.error(message: "Failed to track \(OmetriaEventType.orderCompleted.rawValue) event with error: \(error)", category: .events)
        }
        
    }
    
    // MARK: Notification Related Events
    
    func trackPushTokenRefreshedEvent(pushToken: String) {
        trackEvent(type: .pushTokenRefreshed, data: ["pushToken": pushToken])
        eventHandler.flushEvents()
    }
    
    func trackNotificationReceivedEvent(context: [String: Any]) {
        trackEvent(type: .notificationReceived, data: ["context": context])
    }
    
    func trackNotificationInteractedEvent(context: [String: Any]) {
        trackEvent(type: .notificationInteracted, data: ["context": context])
    }
    
    func trackPermissionsUpdateEvent(hasPermissions: Bool) {
        let permissionsValue = hasPermissions ? "opt-in": "opt-out"
        trackEvent(type: .permissionsUpdate, data: ["notifications": permissionsValue])
    }
    
    // MARK: Other Events
    
    open func trackDeepLinkOpenedEvent(link: String, screenName: String) {
        trackEvent(type: .deepLinkOpened, data: ["link": link,
                                                 "page": screenName])
    }
    
    open func trackCustomEvent(customEventType: String, additionalInfo: [String: Any]) {
        var data = additionalInfo
        data["customEventType"] = customEventType
        trackEvent(type: .custom, data: data)
    }
    
    func trackErrorOccuredEvent(error: OmetriaError) {
        let data = error.errorEventData
        trackEvent(type: .errorOccurred, data: data)
    }
    
    // MARK: - Flush/Clear
    
    open func flush() {
        eventHandler.flushEvents()
    }
    
    open func clear() {
        eventHandler.clearEvents()
    }
    
    // MARK: - Push notifications
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        
        notificationHandler.handleNotificationResponse(response, withCompletionHandler: completionHandler)
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        
        notificationHandler.handleReceivedNotification(notification, withCompletionHandler: completionHandler)
    }
    
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
    }
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
    // MARK: Notification Utils
    
    public static func isOmetriaNotification(_ content: UNNotificationContent) -> Bool {
        guard let aps = content.userInfo["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let _ = alert["ometria"] as? [String: Any] else {
            
                return false
        }
        return true
    }
    
}
