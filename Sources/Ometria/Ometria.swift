//
//  Ometria.swift
//  Ometria
//
//  Created by Cata on 7/10/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

/// The primary class that allows instantiating and integrating Ometria in your application
public class Ometria: NSObject, UNUserNotificationCenterDelegate {
    
    /// string that identifies your project in order to track events to it
    public var apiToken: String
    public var notificationInteractionDelegate: OmetriaNotificationInteractionDelegate? {
        get {
            return notificationHandler.interactionDelegate
        }
        set {
            notificationHandler.interactionDelegate = newValue
        }
    }
    
    static var instance: Ometria?
    private var config: OmetriaConfig
    private let automaticPushTracker = AutomaticPushTracker()
    private let automaticLifecycleTracker = AutomaticLifecycleTracker()
    private let notificationHandler = NotificationHandler()
    private let eventHandler: EventHandler
    
    /**
     Initializes the singleton instance of Ometria with the given api token.
     
     Returns the initialized Ometria instance object.
     
     - Parameter apiToken: the api token that has been attributed to your project.
     
     - Important: Not calling this method before any other will cause an assertion failure.
     
     - Returns: returns an initialized Ometria instance object if needed to use or keep throughout the project. You can always get the initialized instance by calling sharedInstance()
     */
    @discardableResult
    @available(iOSApplicationExtension, unavailable)
    public class func initialize(apiToken: String, enableSwizzling: Bool = true, appGroupIdentifier: String? = nil) -> Ometria {
        clearOldInstanceIfNeeded()
        OmetriaDefaults.appGroupIdentifier = appGroupIdentifier
        OmetriaDefaults.lastUsedAPIToken = apiToken
        let shouldHandleApplicationLaunch = instance == nil
        
        let config = OmetriaConfig()
        config.automaticallyTrackNotifications = enableSwizzling
        let ometria = Ometria(apiToken: apiToken, config: config)
        instance = ometria
        
        if shouldHandleApplicationLaunch {
            ometria.handleApplicationLaunch()
        }
        return ometria
    }
    
    @discardableResult
    public class func initializeForExtension(appGroupIdentifier: String) -> Ometria {
        OmetriaDefaults.appGroupIdentifier = appGroupIdentifier
        
        let config = OmetriaConfig()
        config.automaticallyTrackNotifications = false
        let ometria = Ometria(config: config)
        instance = ometria
        return ometria
    }
    
    /// internal initializer, only used for testing
    @discardableResult
    @available(iOSApplicationExtension, unavailable)
    class func initialize(apiToken: String, eventCache: EventCaching, eventService: EventServiceProtocol, enableSwizzling: Bool = true, appGroupIdentifier: String? = nil) -> Ometria {
        clearOldInstanceIfNeeded()
        let shouldHandleApplicationLaunch = instance == nil
        OmetriaDefaults.lastUsedAPIToken = apiToken
        
        let config = OmetriaConfig()
        config.automaticallyTrackNotifications = enableSwizzling
        let ometria = Ometria(apiToken: apiToken, config: config, eventService: eventService, eventCache: eventCache)
        instance = ometria
        if shouldHandleApplicationLaunch {
            ometria.handleApplicationLaunch()
        }
        return ometria
    }
    
    /**
     Gets the previously initialized Ometria instance
     
     - Returns: returns the Ometria instance
     */
    public class func sharedInstance() -> Ometria {
        guard instance != nil else {
            return Ometria(config: OmetriaConfig())
        }
        return instance!
    }
    
    @available(iOSApplicationExtension, unavailable)
    init(apiToken: String, config: OmetriaConfig) {
        self.config = config
        self.apiToken = apiToken
        let eventServiceConfig = EventServiceConfig(apiToken: apiToken)
        let networkService = NetworkService(config: eventServiceConfig)
        let eventService = EventService(networkService: networkService)
        self.eventHandler = EventHandler(
            eventService: eventService,
            eventCache: EventCache(relativePathComponent: OmetriaDefaults.cacheUniquePathComponent),
            flushLimit: config.flushLimit,
            flushInterval: config.flushInterval
        )
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
        
        self.notificationHandler.interactionDelegate = self
    }
    
    init(config: OmetriaConfig) {
        self.config = config
        self.apiToken = OmetriaDefaults.lastUsedAPIToken
        let eventServiceConfig = EventServiceConfig(apiToken: apiToken)
        let networkService = NetworkService(config: eventServiceConfig)
        let eventService = EventService(networkService: networkService)
        
        self.eventHandler = EventHandler(
            eventService: eventService,
            eventCache: EventCache(relativePathComponent: OmetriaDefaults.cacheUniquePathComponent),
            flushLimit: config.flushLimit,
            flushInterval: config.flushInterval
        )
        super.init()
    }
    
    /// only used for testing purposes, not public
    @available(iOSApplicationExtension, unavailable)
    init(
        apiToken: String,
        config: OmetriaConfig,
        eventService: EventServiceProtocol,
        eventCache: EventCaching
    ) {
        self.config = config
        self.apiToken = apiToken
        self.eventHandler = EventHandler(
            eventService: eventService,
            eventCache: eventCache,
            flushLimit: config.flushLimit,
            flushInterval: config.flushInterval
        )
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
        
        self.notificationHandler.interactionDelegate = self
        
        DispatchQueue.main.async { [weak self] in
            if config.automaticallyTrackNotifications {
                self?.automaticPushTracker.startTracking()
            }
            
            if config.automaticallyTrackAppLifecycle {
                self?.automaticLifecycleTracker.startTracking()
            }
        }
    }
    
    // MARK: - Reinitialization Helpers
    
    private static var oldInstances = [Ometria]()
    private class func clearOldInstanceIfNeeded() {
        guard let instance else {
            return
        }
        
        instance.eventHandler.flushEvents() {
            instance.clear()
        }
        instance.clear()
        
        let swizzles = Swizzler.swizzles
        swizzles.values.forEach { swizzle in
            Swizzler.unswizzleSelector(swizzle.selector, aClass: swizzle.aClass)
        }
        
        resetCacheRelativePath()
    }
    
    /// This will cause the next instance of Ometria that is instantiated to cache events in a new folder. Basically this is making sure that we don't have anything
    private class func resetCacheRelativePath() {
        OmetriaDefaults.cacheUniquePathComponent = UUID().uuidString
    }
    
    // MARK: - Logging
    
    /**
     This allows enabling or disabling runtime logs
     - Note: All logging is disabled by default. This is only required
     when you encounter issues with the SDK and you want to debug it.
     */
    public var isLoggingEnabled: Bool = false {
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
        trackAppInstalledEvent()
    }
    
    private func resetAppInstallationId() {
        let installationID = UUID().uuidString
        OmetriaDefaults.installationID = installationID
    }
    
    // MARK: - Event Tracking
    
    private func trackEvent(type: OmetriaEventType, data: [String: Any] = [:]) {
        let event = OmetriaEvent(eventType: type, data: data)
        eventHandler.processEvent(event)
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
    
    /**
     Track when the user has viewed the "home page" or landing screen of your app.
     */
    public func trackHomeScreenViewedEvent() {
        trackEvent(type: .homeScreenViewed)
    }
    
    /**
     Tracks the event of a new screen being displayed - call this ideally in viewDidAppear(_ animated: Bool)
     
     - Note: Tracking a users independent screen views helps us track engagement of a user with the app, as well as where they are in a journey. An analogous event on a website would be to track independent page views.
     
     - Parameter screenName: the name of the screen
     - Parameter additionalInfo: a dictionary containing any key-value pairs that provide valuable information to your platform
     */
    public func trackScreenViewedEvent(screenName: String, additionalInfo:[String: Any] = [:]) {
        let data: [String: Any] = [Constants.EventKeys.page: screenName,
                                   Constants.EventKeys.additionalInfo: additionalInfo]
        trackEvent(type: .screenViewedExplicit, data: data)
    }
    
    @available(*, deprecated, message: "Automatic screen tracking has been removed")
    func trackScreenViewedAutomaticEvent(screenName: String) {
        trackEvent(type: .screenViewedAutomatic, data: [Constants.EventKeys.page: screenName])
    }
    
    /**
     Tracks the current app user being identified by customerId
     
     An app user has just identified themselves. This basically means: a user has logged in.
     
     - Parameter customerId: the ID reserved for a particular user in your database.
     - Parameter storeId: the storeId of the store where the user is currently shopping. If you want to track a particular store, you can use this.
     
     - Note: If you don't have a customerId, you can use the alternate version of this method: trackProfileIdentifiedEvent(email: String)
     
     - Important: This event is absolutely pivotal to the functioning of the SDK, so take care to send it as early as possible. It is not mutually exclusive with sending an profile identified by e-mail event: send either event as soon as you have the information, for optimal integration.
     */
    public func trackProfileIdentifiedEvent(customerId: String, storeId: String? = nil) {
        OmetriaDefaults.identifiedCustomerID = customerId
        if let storeId {
            OmetriaDefaults.currentStoreID = storeId
        }
        trackProfileIdentifiedEvent()
    }
    
    /**
     Tracks the current app user being identified by email
     
     - Parameter email: the email by which you identify a particular user in your database
     - Parameter storeId: the storeId of the store where the user is currently shopping. If you want to track a particular store, you can use this.
     
     - Important: Having a customerId makes profile matching more robust. It is not mutually exclusive with sending an profile identified by customerId event: send either event as soon as you have the information, for optimal integration.
     */
    public func trackProfileIdentifiedEvent(email: String, storeId: String? = nil) {
        OmetriaDefaults.identifiedCustomerEmail = email
        if let storeId {
            OmetriaDefaults.currentStoreID = storeId
        }
        trackProfileIdentifiedEvent()
    }
  
    /**
     Tracks the current app user being identified by customerId and email
      
     - Parameter customerId: the ID reserved for a particular user in your database.
     - Parameter email: the email by which you identify a particular user in your database
     - Parameter storeId: the storeId of the store where the user is currently shopping. If you want to track a particular store, you can use this.
     */
    public func trackProfileIdentifiedEvent(customerId: String, email: String, storeId: String? = nil) {
        OmetriaDefaults.identifiedCustomerID = customerId
        OmetriaDefaults.identifiedCustomerEmail = email
        if let storeId {
            OmetriaDefaults.currentStoreID = storeId
        }
        trackProfileIdentifiedEvent()
    }
    
    private func trackProfileIdentifiedEvent() {
        var data: [String: Any] = [:]
        
        if let email = OmetriaDefaults.identifiedCustomerEmail {
            data[Constants.EventKeys.email] = email
        }
        if let customerId = OmetriaDefaults.identifiedCustomerID {
            data[Constants.EventKeys.customerId] = customerId
        }
        if let storeId = OmetriaDefaults.currentStoreID {
            data[Constants.EventKeys.storeId] = storeId
        }
        
        trackProfileIdentifiedEvent(data: data)
    }
    
    private func trackProfileIdentifiedEvent(data: [String: Any]) {
        trackEvent(type: .profileIdentified, data: data)
        
        if let fcmToken = OmetriaDefaults.fcmToken {
            trackPushTokenRefreshedEvent(pushToken: fcmToken)
        }
    }
    
    /**
     Track the current app user being deidentified
     
     An app user has deidentified themselves. This basically means: a user has logged out
     */
    public func trackProfileDeidentifiedEvent() {
        OmetriaDefaults.identifiedCustomerEmail = nil
        OmetriaDefaults.identifiedCustomerID = nil
        OmetriaDefaults.currentStoreID = nil
        trackEvent(type: .profileDeidentified)
    }
    
    // MARK: Product Related Events
    
    /**
     Track whenever a visitor clicks / taps / views / highlights or otherwise shows interest in a product.
     
     - Parameter productId: the unique identifier for the product that has been interacted with.
     */
    public func trackProductViewedEvent(productId: String) {
        trackEvent(type: .productViewed, data: [Constants.EventKeys.productId: productId])
    }
    
    
    /**
     Track whenever a visitor clicks / taps / views / highlights or otherwise shows interest in a product listing.
     
     - Parameter listingType: A string representing the type of the listing. Can be category or search or other.
     - Parameter listingAttributes: A dictionary containing the parameters associated with the listing. Can contain a category id or a search query for example.
     */
    public func trackProductListingViewedEvent(listingType: String? = nil, listingAttributes: [String: Any]? = nil) {
        var data: [String: Any] = [:]
        if let listingType = listingType {
            data[Constants.EventKeys.listingType] = listingType
        }
        if let listingAttributes = listingAttributes {
            data[Constants.EventKeys.listingAttributes] = listingAttributes
        }
        
        trackEvent(type: .productListingViewed, data: data)
    }
    
    /**
     Track when a user has added a product to their wishlist
     
     - Parameter productId: the unique identifier of the product that has been added to the wishlist
     */
    @available(*, deprecated, message: "the event is no longer sent to the Ometria backend. It will be removed in a future version.")
    public func trackWishlistAddedToEvent(productId: String) {
        Logger.warning(message: "The WishlistAddedTo event is no longer processed by Ometria. It will not produce any result.")
    }
    
    /**
     Track when a user has removed a product to their wishlist
     
     - Parameter productId: the unique identifier of the product that has been removed from the wishlist
     */
    @available(*, deprecated, message: "the event is no longer sent to the Ometria backend. It will be removed in a future version.")
    public func trackWishlistRemovedFromEvent(productId: String) {
        Logger.warning(message: "The WishlistRemovedFrom event is no longer processed by Ometria. It will not produce any result.")
    }
    
    /**
     Track when the user has viewed a dedicated page, screen or modal with the contents of the shopping basket.
     */
    public func trackBasketViewedEvent() {
        trackEvent(type: .basketViewed)
    }
    
    /**
     Track when the user has changed their shopping basket content.
     
     - Parameters basket: an OmetriaBasket object with all the available details of the current basket contents
     */
    public func trackBasketUpdatedEvent(basket: OmetriaBasket) {
        do {
            let serializedBasket = try basket.jsonObject()
            trackEvent(type: .basketUpdated, data: [Constants.EventKeys.basket: serializedBasket])
        } catch {
            Logger.error(message: "Failed to track \(OmetriaEventType.basketUpdated.rawValue) event with error: \(error)", category: .events)
        }
    }
    
    /**
     Track when the user has started the checkout process.
     
     - Parameter orderId: The id that your system generated for the order that is being checked out
     */
    public func trackCheckoutStartedEvent(orderId: String? = nil) {
        var data: [String: Any] = [:]
        if let orderId = orderId {
            data[Constants.EventKeys.orderId] = orderId
        }
        trackEvent(type: .checkoutStarted, data: data)
    }
    
    /**
     Track when an order has been completed and paid for.
     
     - Parameter orderId: The id that your system generated for the completed order
     - Parameter basket: an OmetriaBasket object containing all the items in the order and also the total pricing and currency
     */
    public func trackOrderCompletedEvent(orderId: String, basket: OmetriaBasket? = nil) {
        do {
            var data: [String: Any] = [Constants.EventKeys.orderId: orderId]
            if let basket = basket {
                let serializedBasket = try basket.jsonObject()
                data[Constants.EventKeys.basket] = serializedBasket
            }
            trackEvent(type: .orderCompleted, data: data)
        } catch {
            Logger.error(message: "Failed to track \(OmetriaEventType.orderCompleted.rawValue) event with error: \(error)", category: .events)
        }
    }
    
    // MARK: Notification Related Events
    
    func trackPushTokenRefreshedEvent(pushToken: String) {
        var data = [Constants.EventKeys.pushToken: pushToken]
        
        if let customerEmail = OmetriaDefaults.identifiedCustomerEmail {
            data[Constants.EventKeys.email] = customerEmail
        }
        
        if let customerId = OmetriaDefaults.identifiedCustomerID {
            data[Constants.EventKeys.customerId] = customerId
        }
        
        if let storeId = OmetriaDefaults.currentStoreID {
            data[Constants.EventKeys.storeId] = storeId
        }
        
        notificationHandler.verifyPushNotificationAuthorizationStatus {[weak self] (hasAuthorization) in
            data[Constants.EventKeys.notifications] = hasAuthorization ? Constants.EventPredefinedValues.optIn : Constants.EventPredefinedValues.optOut
            OmetriaDefaults.fcmTokenLastRefreshDate = Date()
            self?.trackEvent(type: .pushTokenRefreshed, data: data)
            OmetriaDefaults.fcmTokenLastRefreshDate = Date()
            self?.eventHandler.flushEvents(isFlushRateLimitEnabled: false)
        }
    }
    
    func trackNotificationReceivedEvent(context: [String: Any]) {
        trackEvent(type: .notificationReceived, data: [Constants.EventKeys.context: context])
    }
    
    func trackNotificationInteractedEvent(context: [String: Any]) {
        trackEvent(type: .notificationInteracted, data: [Constants.EventKeys.context: context])
    }
    
    func trackPermissionsUpdateEvent(hasPermissions: Bool) {
        let permissionsValue = hasPermissions ? Constants.EventPredefinedValues.optIn: Constants.EventPredefinedValues.optOut
        trackEvent(type: .permissionsUpdate, data: [Constants.EventKeys.notifications: permissionsValue])
    }
    
    // MARK: Other Events
    
    /**
     track whenever a deep/universal link is opened in the app
     
     - Parameters link: a string representing the URL that has been opened
     - Parameters screenName: a string representing the name of the screen that has been opened as a result of decomposing the URL
     */
    public func trackDeepLinkOpenedEvent(link: String, screenName: String) {
        trackEvent(type: .deepLinkOpened, data: [Constants.EventKeys.link: link,
                                                 Constants.EventKeys.page: screenName])
    }
    
    /**
     track any specific flows or pages that are of interest to the marketing department
     
     - Parameter customEventType: a string representing the name of the custom event
     - Parameter additionalInfo: a dictionary containing any key-value pairs that provide valuable information to your platform
     */
    public func trackCustomEvent(customEventType: String, additionalInfo: [String: Any]? = nil) {
        var data: [String: Any] = [Constants.EventKeys.customEventType: customEventType]
        if let additionalInfo = additionalInfo {
            data[Constants.EventKeys.properties] = additionalInfo
        }
        trackEvent(type: .custom, data: data)
    }
    
    func trackErrorOccuredEvent(error: OmetriaError) {
        let data = error.errorEventData
        trackEvent(type: .errorOccurred, data: data)
    }
    
    // MARK: - Store Identifier
    
    /**
     updates the store identifier for the current user
     
     - Parameter storeId: a string representing the store identifier
     */
    
    public func updateStoreId(storeId: String?) {
        OmetriaDefaults.currentStoreID = storeId
        trackProfileIdentifiedEvent()
    }
    
    // MARK: - Flush/Clear
    
    /**
     Uploads tracked events data to the Ometria server.
     
     By default, tracked events are flushed to the Ometria servers every time it reaches a limit of 10 events, but no earlier than 10 seconds from the last flush operation. You only need to call this
     method manually if you want to force a flush at a particular moment.
     */
    public func flush() {
        eventHandler.flushEvents()
    }
    
    /**
     Clears all the events from local cache
     */
    public func clear() {
        eventHandler.clearEvents()
    }
    
    // MARK: - Push notifications
    
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
    }
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void)
    {
        
        notificationHandler.handleNotificationResponse(response.notification.request.content.userInfo, withCompletionHandler: completionHandler)
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        
        notificationHandler.handleReceivedNotification(notification.request.content.userInfo, withCompletionHandler: completionHandler)
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
    // MARK: Manual Notification Tracking
    public func handleFirebaseTokenChanged(token: String) {
        automaticPushTracker.processFirebaseToken(token)
    }
    
    public func handleNotificationResponse(_ response: UNNotificationResponse) {
        notificationHandler.handleNotificationResponse(response.notification.request.content.userInfo, withCompletionHandler: nil)
    }
    
    public func handleReceivedNotification(_ notification: UNNotification) {
        notificationHandler.handleReceivedNotification(notification.request.content.userInfo, withCompletionHandler: nil)
    }
    
    // MARK: Notification Utils
    
    /**
     Validates if a notification comes from ometria by checking its content
     
     - Parameter content: The content taken from a UNNotification that has been received
     
     - Returns: A Bool indicating whether the notification is recognized as coming from Ometria servers.
     */
    public static func isOmetriaNotification(_ content: UNNotificationContent) -> Bool {
        guard let aps = content.userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let _ = alert["ometria"] as? [String: Any] else {
                  
                  return false
              }
        
        return true
    }
    
    /**
     Validates if a notification comes from ometria by checking its content and retrieves an OmetriaNotification object
     
     - Parameter content: The content of a push notification that has been received.
     
     - Returns: An optional OmetriaNotification object
     */
    public func parseNotification(_ content: UNNotificationContent) -> OmetriaNotification? {
        guard Ometria.isOmetriaNotification(content) else {
            return nil
        }
        
        return notificationHandler.parseOmetriaNotification(content.userInfo)
    }
  
    // MARK: Universal Links
    
    /**
     Retrieves the redirect url for the url that you provide.
     
     - Parameter url: The url that will be processed.
     - Parameter callback: The callback that provides the final redirect url if retreived, or an error if something went wrong.
     
     - Note: If no redirect url is found, the initial url will be provided in the callback.
     */
    open func processUniversalLink(_ url: URL, callback: @escaping (URL?, Error?)->()) {
          RedirectService().getRedirect(url: url, domain: nil, regex: nil, callback: callback)
    }

    /**
     Retrieves the redirect url for the url that you provide.
     
     - Parameter url: The url that will be processed.
     - Parameter domain: If a url that belongs to the given domain is found, then that is returned in the callback. Otherwise the callback returns the url retrieved after the last redirect.
     - Parameter callback: The callback that provides the final redirect url if retreived, or an error if something went wrong.
     
     - Note: If no redirect url is found, the initial url will be provided in the callback.
     */
    open func processUniversalLink(_ url: URL, domain: String, callback: @escaping (URL?, Error?)->()) {
          RedirectService().getRedirect(url: url, domain: domain, regex: nil, callback: callback)
    }

    /**
     Retrieves the redirect url for the url that you provide.
     
     - Parameter url: The url that will be processed.
     - Parameter regex: If a url that matches the given regex is found, then that is returned in the callback. Otherwise the callback returns the url retrieved after the last redirect.
     - Parameter callback: The callback that provides the final redirect url if retreived, or an error if something went wrong.
     
     - Note: If no redirect url is found, the initial url will be provided in the callback.
     */
    open func processUniversalLink(_ url: URL, regex: String, callback: @escaping (URL?, Error?)->()) {
          RedirectService().getRedirect(url: url, domain: nil, regex: regex, callback: callback)
    }
}

// MARK: - Deeplink Interaction

@available(iOSApplicationExtension, unavailable)
extension Ometria: OmetriaNotificationInteractionDelegate {
    
    public func handleOmetriaNotificationInteraction(_ notification: OmetriaNotification) {
        guard let urlString = notification.deepLinkActionUrl?.trimmingCharacters(in: .init(charactersIn: " ")),
              let urlEncodingString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                  return
              }
        
        guard let url = URL(string: urlEncodingString) else {
            Logger.error(message: "The provided deeplink URL \(urlString) is invalid", category: .push)
            return
        }
        
        if Ometria.sharedUIApplication()?.canOpenURL(url) == true {
            Logger.debug(message: "Open URL: \(urlString)", category: .push)
            Ometria.sharedUIApplication()?.open(url)
            trackDeepLinkOpenedEvent(link: url.absoluteString, screenName: "Safari")
        } else {
            Logger.error(message: "Can not open \(url.absoluteString)", category: .push)
        }
    }
}

// MARK: - Manual Notification Tracking - React Native
extension Ometria {
    public func handleNotificationResponse(_ userInfo: [AnyHashable: Any]) {
        notificationHandler.handleNotificationResponse(userInfo, withCompletionHandler: nil)
    }
    
    public func handleReceivedNotification(_ userInfo: [AnyHashable: Any]) {
        notificationHandler.handleReceivedNotification(userInfo, withCompletionHandler: nil)
    }
}

//MARK: - Rich push notifications
public extension Ometria {
    /**
     Call this method from your `NotificationService.didReceive` function.
     It will automatically track the notification-received event and
     process any rich push content (like images) before calling your `contentHandler`.
     
     - Parameter request: The original `UNNotificationRequest` received by the service extension.
     - Parameter ometria: An initialized instance of the Ometria SDK.
     - Parameter contentHandler: The `contentHandler` closure from the `didReceive` method.
     */
    public func handleNotification(
        _ request: UNNotificationRequest,
        using ometria: Ometria,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        OmetriaNotificationProcessor.handleNotification(
            request,
            using: self,
            contentHandler: contentHandler
        )
    }
}
