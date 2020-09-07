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
    var automaticallyTrackNotifications: Bool = true
    var automaticallyTrackAppLifecycle: Bool = true
    var automaticallyTrackScreenListing: Bool = true
    var isLoggingEnabled: Bool = false
    var logLevel: LogLevel = .warning
    
    init(flushLimit: Int = Constants.defaultTriggerLimit) {
        self.flushLimit = flushLimit
    }
}
