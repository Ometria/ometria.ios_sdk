//
//  Preferences.swift
//  Ometria
//
//  Created by Cata on 7/10/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

open class Preferences {
    
    public var flushLimit: Int
    var automaticallyTrackNotifications: Bool = true
    var automaticallyTrackAppLifecycle: Bool = true
    var automaticallyTrackScreenListing: Bool = true
    var isLoggingEnabled: Bool = true
    var logLevel: LogLevel = .warning
    
    public init(flushLimit: Int = 20) {
        self.flushLimit = flushLimit
    }
}
