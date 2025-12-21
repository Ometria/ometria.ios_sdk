//
//  Constants.swift
//  Ometria
//
//  Created by Cata on 8/25/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

public enum Constants {
    static let sdkVersion = "1.8.4"
    public static let defaultTriggerLimit = 10
    public static let defaultFlushInterval = 60
    static let flushMaxBatchSize = 100
    static let networkCallTimeoutSeconds: TimeInterval = 10
    static let tooManyRequestsStatusCode: Int = 429
    
    enum UserDefaultsKeys {
        static let sdkVersionRN: String = "sdkVersionRN"
        static let lastUsedAPIToken: String = "com.ometria.lastUsedAPIToken"
    }
}

extension Constants {
    internal enum EventKeys {
        static let page: String = "page"
        static let additionalInfo: String = "extra"
        static let customerId: String = "customerId"
        static let storeId: String = "storeId"
        static let orderId: String = "orderId"
        static let email: String = "email"
        static let productId: String = "productId"
        static let listingType: String = "listingType"
        static let listingAttributes: String = "listingAttributes"
        static let basket: String = "basket"
        static let notifications: String = "notifications"
        static let pushToken: String = "pushToken"
        static let context: String = "context"
        static let link: String = "link"
        static let customEventType: String = "customEventType"
        static let properties: String = "properties"
    }
    
    internal enum EventPredefinedValues {
        static let optIn = "opt-in"
        static let optOut = "opt-out"
    }
}
