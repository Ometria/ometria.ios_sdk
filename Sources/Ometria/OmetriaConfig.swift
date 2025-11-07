//
//  OmetriaConfig.swift
//  Ometria
//
//  Created by Cata on 7/10/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

class OmetriaConfig {
    var flushLimit: Int
    let flushInterval: Int
    var automaticallyTrackNotifications: Bool = true
    var automaticallyTrackAppLifecycle: Bool = true
    var isLoggingEnabled: Bool = false
    var logLevel: LogLevel = .warning
    
    init(
        flushLimit: Int = Constants.defaultTriggerLimit,
        flushInterval: Int = Constants.defaultFlushInterval
    ) {
        self.flushLimit = flushLimit
        self.flushInterval = flushInterval
    }
}
