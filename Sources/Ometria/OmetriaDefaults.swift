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
    let suiteClosure: ()->String?
    
    init(suite: @autoclosure @escaping ()->String? = {nil}(), key: String, defaultValue: T) {
        self.key = key
        self.suiteClosure = suite
        self.defaultValue = defaultValue
    }
    
    private var userDefaults: UserDefaults {
        let suite = suiteClosure()
        return suite.flatMap({ UserDefaults(suiteName: $0) }) ?? .standard
    }
    
    var wrappedValue: T {
        get {
            let value = userDefaults.object(forKey: key) as? T
            let flatValue: T = value.flatMap({ $0 }) ?? defaultValue
            switch flatValue as Any {
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
                userDefaults.set(containedValue, forKey: key)
            case Optional<Any>.none:
                userDefaults.removeObject(forKey: key)
            default:
                userDefaults.set(newValue, forKey: key)
            }
        }
    }
}

enum OmetriaDefaults {
    @UserDefault(key: "com.ometria.cacheUniquePathComponent", defaultValue: UUID().uuidString)
    private static var __cacheUniquePathComponent: String
    @UserDefault(key: "com.ometria.is_first_launch", defaultValue: true)
    private static var __isFirstLaunch: Bool
    @UserDefault(key: "com.ometria.apple_push_token", defaultValue: nil)
    private static var __applePushToken: String?
    @UserDefault(key: "com.ometria.fcm_token", defaultValue: nil)
    private static var __fcmToken: String?
    @UserDefault(key: "com.ometria.last_launch_date", defaultValue: nil)
    private static var __lastLaunchDate: Date?
    @UserDefault(key: "com.ometria.installment_id", defaultValue: nil)
    private static var __installationID: String?
    @UserDefault(key: "com.ometria.notification_process_date", defaultValue: Date(timeIntervalSince1970: 0))
    private static var __notificationProcessDate: Date
    @UserDefault(key: "com.ometria.pushNotificationSettings", defaultValue: 0)
    private static var __lastKnownNotificationAuthorizationStatus: Int
    @UserDefault(key: "com.ometria.networkTimedOutUntilDate", defaultValue: Date(timeIntervalSince1970: 0))
    private static var __networkTimedOutUntilDate: Date
    @UserDefault(key: "com.ometria.identifiedCustomerEmail", defaultValue: nil)
    private static var __identifiedCustomerEmail: String?
    @UserDefault(key: "com.ometria.identifiedCustomerID", defaultValue: nil)
    private static var __identifiedCustomerID: String?
    @UserDefault(key: Constants.UserDefaultsKeys.sdkVersionRN, defaultValue: nil)
    private static var __sdkVersionRN: String?
    
    
    @UserDefault(key: "com.ometria.appGroupIdentifier", defaultValue: nil)
    static var appGroupIdentifier: String?
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.cacheUniquePathComponent", defaultValue: __cacheUniquePathComponent)
    static var cacheUniquePathComponent: String
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.is_first_launch", defaultValue: __isFirstLaunch)
    static var isFirstLaunch: Bool
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.apple_push_token", defaultValue: __applePushToken)
    static var applePushToken: String?
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.fcm_token", defaultValue: __fcmToken)
    static var fcmToken: String?
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.last_launch_date", defaultValue: __lastLaunchDate)
    static var lastLaunchDate: Date?
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.installment_id", defaultValue: __installationID)
    static var installationID: String?
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.notification_process_date", defaultValue: __notificationProcessDate)
    static var notificationProcessDate: Date
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.pushNotificationSettings", defaultValue: __lastKnownNotificationAuthorizationStatus)
    static var lastKnownNotificationAuthorizationStatus: Int
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.networkTimedOutUntilDate", defaultValue: __networkTimedOutUntilDate)
    static var networkTimedOutUntilDate: Date
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.identifiedCustomerEmail", defaultValue: __identifiedCustomerEmail)
    static var identifiedCustomerEmail: String?
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.identifiedCustomerID", defaultValue: __identifiedCustomerID)
    static var identifiedCustomerID: String?
    @UserDefault(suite: appGroupIdentifier, key: Constants.UserDefaultsKeys.sdkVersionRN, defaultValue: __sdkVersionRN)
    internal static var sdkVersionRN: String?
    @UserDefault(suite: appGroupIdentifier, key: Constants.UserDefaultsKeys.lastUsedAPIToken, defaultValue: "")
    internal static var lastUsedAPIToken: String
    @UserDefault(suite: appGroupIdentifier, key: "com.ometria.storeID", defaultValue: nil)
    internal static var currentStoreID: String?
}
