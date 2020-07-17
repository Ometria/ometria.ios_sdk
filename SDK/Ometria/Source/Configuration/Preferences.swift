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
    var trackNotifications: Bool = true
    var trackAppLifecycle: Bool = true
    var trackScreenListing: Bool = true
    
    public init(flushLimit: Int = 20) {
        self.flushLimit = flushLimit
    }
}
