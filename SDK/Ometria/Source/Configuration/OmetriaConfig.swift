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
    var automaticallyTrackNotifications: Bool = true
    var automaticallyTrackAppLifecycle: Bool = true
    var automaticallyTrackScreenListing: Bool = true
    var isLoggingEnabled: Bool = true
    var logLevel: LogLevel = .warning
    
    public init(flushLimit: Int = 5) {
        self.flushLimit = flushLimit
    }
}
