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
    open var preferences: Preferences
    public static var sharedInstance: Ometria?
    let pushTracker = AutomaticPushTracker()
    
    open class func initialize(apiToken: String, preferences: Preferences = Preferences()) {
        let ometria = Ometria(preferences: preferences)
        ometria.apiToken = apiToken
        sharedInstance = ometria
    }
    
    init(preferences: Preferences) {
        self.preferences = preferences
        pushTracker.startTracking()
    }
}
