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
    @UserDefault(key: "com.ometria.is_first_launch", defaultValue: true)
    static var isFirstLaunch: Bool
    @UserDefault(key: "com.ometria.apple_push_token", defaultValue: nil)
    static var applePushToken: String?
    @UserDefault(key: "com.ometria.fcm_token", defaultValue: nil)
    static var fcmToken: String?
    @UserDefault(key: "com.ometria.last_launch_date", defaultValue: nil)
    static var lastLaunchDate: Date?
    @UserDefault(key: "com.ometria.installment_id", defaultValue: nil)
    static var installationID: String?
    @UserDefault(key: "com.ometria.notification_process_date", defaultValue: Date(timeIntervalSince1970: 0))
    static var notificationProcessDate: Date
    @UserDefault(key: "com.ometria.pushNotificationSettings", defaultValue: 0)
    static var lastKnownNotificationAuthorizationStatus: Int
    @UserDefault(key: "com.ometria.networkTimedOutUntilDate", defaultValue: Date(timeIntervalSince1970: 0))
    static var networkTimedOutUntilDate: Date
}
