//
//  OmetriaDefaults.swift
//  Ometria
//
//  Created by Cata on 7/24/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {
  let key: String
  let defaultValue: T
  
  var wrappedValue: T {
    get {
        let value = UserDefaults.standard.object(forKey: key) as? T
        switch value as Any {
        case Optional<Any>.some(let containedValue):
            return containedValue as! T
        case Optional<Any>.none:
            return defaultValue
        default:
            return value ?? defaultValue
      }
    }
    set {
        switch newValue as Any {
        case Optional<Any>.some(let containedValue):
            UserDefaults.standard.set(containedValue, forKey: key)
        case Optional<Any>.none:
            UserDefaults.standard.removeObject(forKey: key)
        default:
            UserDefaults.standard.set(newValue, forKey: key)
      }
    }
  }
}

struct OmetriaDefaults {
    @UserDefault(key: "com.ometria.did_run_more_than_once", defaultValue: false)
    static var didRunMoreThanOnce: Bool
    @UserDefault(key: "com.ometria.apple_push_token", defaultValue: nil)
    static var applePushToken: String?
    @UserDefault(key: "com.ometria.fcm_token", defaultValue: nil)
    static var fcmToken: String?
    @UserDefault(key: "com.ometria.last_launch_date", defaultValue: nil)
    static var lastLaunchDate: Date?
}
