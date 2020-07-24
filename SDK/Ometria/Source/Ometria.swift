//
//  Ometria.swift
//  Ometria
//
//  Created by Cata on 7/10/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

open class Ometria {
    
    open var apiToken: String?
    private var preferences: Preferences
    static var instance: Ometria?
    let automaticPushTracker = AutomaticPushTracker()
    let automaticLifecycleTracker = AutomaticLifecycleTracker()
    
    @discardableResult
    open class func initialize(apiToken: String, preferences: Preferences = Preferences()) -> Ometria {
        let ometria = Ometria(preferences: preferences)
        ometria.apiToken = apiToken
        instance = ometria
        return ometria
    }
    
    open class func sharedInstance() -> Ometria {
        guard instance != nil else {
            assert(false, "You are not allowed to call the sharedInstance() method before calling initialize(apiToken:preferences:).")
        }
        return instance!
    }
    
    init(preferences: Preferences) {
        self.preferences = preferences
        automaticPushTracker.startTracking()
        isLoggerEnabled = true
    }
    
    open var isLoggerEnabled: Bool = false {
        didSet {
            if isLoggerEnabled {
                Logger.enableLevel(.debug)
                Logger.enableLevel(.info)
                Logger.enableLevel(.warning)
                Logger.enableLevel(.error)

                Logger.info(message: "Logger Enabled")
            } else {
                Logger.info(message: "Logger Disabled")

                Logger.disableLevel(.debug)
                Logger.disableLevel(.info)
                Logger.disableLevel(.warning)
                Logger.disableLevel(.error)
            }
        }
    }
    
    open func trackEvent(_ event: Event) {
        Logger.info(message: "Track Event \(event)", category: LogCategory.events)
    }
    
    open func trackEvent(type: OmetriaEventType, value: String, configurationBlock: (( _ event: Event) -> Void)? = nil) {
        let event = Event(type: .addProductToCart, value: value)
        configurationBlock?(event)
        trackEvent(event)
    }
    
    open func trackCustomEvent(customEventType: String, value: String, configurationBlock: (( _ event: Event) -> Void)? = nil) {
        trackEvent(type: .custom(customType: customEventType), value: value, configurationBlock: configurationBlock)
    }
    
    
}
