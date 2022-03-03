//
//  OmetriaConfig.swift
//  Ometria
//
//  Created by Cata on 7/10/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

open class OmetriaConfig {
    
    open var flushLimit: Int
    open var automaticallyTrackNotifications: Bool
    open var automaticallyTrackAppLifecycle: Bool
    open var isLoggingEnabled: Bool
    open var logLevel: LogLevel

    init(flushLimit: Int = Constants.defaultTriggerLimit, automaticallyTrackNotifications: Bool = true, automaticallyTrackAppLifecycle: Bool = true, isLoggingEnabled: Bool = false, logLevel: LogLevel = .warning) {
        self.flushLimit = flushLimit
        self.automaticallyTrackNotifications = automaticallyTrackAppLifecycle
        self.automaticallyTrackAppLifecycle = automaticallyTrackAppLifecycle
        self.isLoggingEnabled = isLoggingEnabled
        self.logLevel = logLevel
    }
}
