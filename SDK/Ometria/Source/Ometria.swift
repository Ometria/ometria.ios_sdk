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
    public static var sharedInstance: Ometria?
    let automaticPushTracker = AutomaticPushTracker()
    let automaticLifecycleTracker = AutomaticLifecycleTracker()
    
    open class func initialize(apiToken: String, preferences: Preferences = Preferences()) {
        let ometria = Ometria(preferences: preferences)
        ometria.apiToken = apiToken
        sharedInstance = ometria
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
    
    open func trackEvent() -> Event {
        return Event(type: .newAppSession, value: "")
    }
}
