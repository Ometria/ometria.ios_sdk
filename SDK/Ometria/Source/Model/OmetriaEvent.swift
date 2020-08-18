//
//  OmetriaEvent.swift
//  Ometria
//
//  Created by Cata on 7/22/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

public enum OmetriaEventType: String, Codable {
    
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
    case custom
    
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
        case .custom: return "custom"
        }
    }
}

class OmetriaEvent: CustomDebugStringConvertible, Codable {
    var appId = Bundle.main.bundleIdentifier ?? "unknown"
    var installationId = OmetriaDefaults.installationID ?? "unknown"
    var appVersion: String?
    var appBuildNumber: String?
    var sdkVersion: String
    var platform = UIDevice.current.systemName
    var osVersion = UIDevice.current.systemVersion
    var deviceManufacturer = "Apple"
    var deviceModel = UIDevice.current.model
    var timestampOccurred = Date()
    var isAutomaticallyTracked = false
    
    var eventType: OmetriaEventType
    var data: [String: Codable] = [:]
    
    enum CodingKeys: String, CodingKey {
       case appId
       case installationId
       case appVersion
       case appBuildNumber
       case sdkVersion
       case platform
       case osVersion
       case deviceManufacturer
       case deviceModel
       case timestampOccurred
       case isAutomaticallyTracked
       case eventType = "type"
       case data
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        appId = try values.decode(String.self, forKey: .appId)
        installationId = try values.decode(String.self, forKey: .installationId)
        appVersion = try values.decode(String.self, forKey: .appVersion)
        appBuildNumber = try values.decode(String.self, forKey: .appBuildNumber)
        sdkVersion = try values.decode(String.self, forKey: .sdkVersion)
        platform = try values.decode(String.self, forKey: .platform)
        osVersion = try values.decode(String.self, forKey: .osVersion)
        deviceManufacturer = try values.decode(String.self, forKey: .deviceManufacturer)
        deviceModel = try values.decode(String.self, forKey: .deviceModel)
        timestampOccurred = try values.decode(Date.self, forKey: .timestampOccurred)
        isAutomaticallyTracked = try values.decode(Bool.self, forKey: .isAutomaticallyTracked)
        eventType = try values.decode(OmetriaEventType.self, forKey: .eventType)
        
        if values.contains(.data), let jsonData = try? values.decode(Data.self, forKey: .data) {
            data = (try? JSONSerialization.jsonObject(with: jsonData) as? [String : Codable]) ?? [String:Codable]()
        } else {
            data = [String:Codable]()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !data.isEmpty, let jsonData = try? JSONSerialization.data(withJSONObject: data) {
            try container.encode(jsonData, forKey: .data)
        }
        try container.encode(appId, forKey: .appId)
        try container.encode(installationId, forKey: .installationId)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(appBuildNumber, forKey: .appBuildNumber)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(platform, forKey: .platform)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(deviceManufacturer, forKey: .deviceManufacturer)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(timestampOccurred, forKey: .timestampOccurred)
        try container.encode(isAutomaticallyTracked, forKey: .isAutomaticallyTracked)
        try container.encode(eventType, forKey: .eventType)
    }
    
    public init(eventType: OmetriaEventType, data: [String: Codable]) {
        self.eventType = eventType
        self.data = data
        
        let infoDict = Bundle.main.infoDictionary
        if let infoDict = infoDict {
            appBuildNumber = infoDict["CFBundleVersion"] as? String
            appVersion = infoDict["CFBundleShortVersionString"] as? String
        }
        
        sdkVersion = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    public var debugDescription: String {
        return "\(eventType.id):" +
        "   data: \(data)"
    }
}
