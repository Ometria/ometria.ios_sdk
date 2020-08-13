//
//  OmetriaEvent.swift
//  Ometria
//
//  Created by Cata on 7/22/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

public enum OmetriaEventType {
    // MARK: Product related event types
    case basketUpdated
    case basketViewed
    case orderCompleted
    case productCategoryViewed
    case productViewed
    case wishlistAddedTo
    case wishlistRemovedFrom
    
    // MARK: Application related event types
    case appInstalled
    case appLaunched
    case appBackgrounded
    case appForegrounded
    case screenViewed
    case profileIdentified
    case profileDeidentified
    
    // MARK: Notification related event types
    case pushTokenRefreshed
    case notificationReceived
    case notificationInteracted
    
    // MARK: Other event types
    case deepLinkOpened
    case custom(customType: String)
    
    var id: String {
        switch self {
        case .appInstalled: return "appInstalled"
        case .appLaunched: return "appLaunched"
        case .appBackgrounded: return "appBackgrounded"
        case .appForegrounded: return "appForegrounded"
        case .screenViewed: return "screenViewed"
            
        case .basketUpdated: return "basketUpdated"
        case .basketViewed: return "basketViewed"
        case .orderCompleted: return "orderCompleted"
        case .productCategoryViewed: return "productCategoryViewed"
        case .productViewed: return "productViewed"
        case .wishlistAddedTo: return "wishlistAddedTo"
        case .wishlistRemovedFrom: return "wishlistRemovedFrom"
            
        case .profileIdentified: return "profileIdentified"
        case .profileDeidentified: return "profileDeidentified"
        case .pushTokenRefreshed: return "pushTokenRefreshed"
        case .notificationInteracted: return "notificationInteracted"
        case .notificationReceived: return "notificationReceived"
        case .deepLinkOpened: return "deepLinkOpened"
        case .custom(let customType): return customType
        }
    }
}

class OmetriaEvent {
    var applicationID = Bundle.main.bundleIdentifier!
    var installmentID: String
    var applicationVersion: String
    var buildNumber: String
    var sdkVersion: String
    let platform = UIDevice.current.systemName
    let osVersion = UIDevice.current.systemVersion
    let deviceManufacturer = "Apple"
    let deviceModel = UIDevice.current.model
    let creationDate = Date()
    var flushDate: Date?
    var isFlushed = false
    var isAutomaticallyTracked = false
    
    var type: OmetriaEventType
    var data: [String: Codable] = [:]
    
    public init(type: OmetriaEventType, data: [String: Codable]) {
        self.type = type
        self.data = data
        applicationID = ""
        applicationVersion = ""
        buildNumber = ""
        sdkVersion = ""
        installmentID = ""
    }
    
    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public var debugDescription: String {
        return "\(type.id):" +
        "   data: \(data)"
    }
}
