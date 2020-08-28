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
    case screenViewedAutomatic
    case screenViewedExplicit
    case profileIdentified
    case profileDeidentified
    
    // MARK: Notification related event types
    case pushTokenRefreshed
    case notificationReceived
    case notificationInteracted
    case permissionsUpdate
    
    // MARK: Other event types
    case deepLinkOpened
    case custom
    
    var id: String {
        switch self {
        case .appInstalled: return "appInstalled"
        case .appLaunched: return "appLaunched"
        case .appBackgrounded: return "appBackgrounded"
        case .appForegrounded: return "appForegrounded"
        case .screenViewedAutomatic: return "screenViewedAutomatic"
        case .screenViewedExplicit: return "screenViewedExplicit"
            
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
        case .permissionsUpdate: return "permissionsUpdate"
        case .deepLinkOpened: return "deepLinkOpened"
        case .custom: return "custom"
        }
    }
}

class OmetriaEvent: CustomDebugStringConvertible, Codable {
    var eventId: String
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
    var isBeingFlushed = false
    
    var eventType: OmetriaEventType
    var data: [String: Any] = [:]
    
    enum CodingKeys: String, CodingKey {
        case eventId
        case appId
        case installationId
        case appVersion
        case appBuildNumber
        case sdkVersion
        case platform
        case osVersion
        case deviceManufacturer
        case deviceModel
        case dtOccurred
        case isBeingFlushed
        
        case eventType = "type"
        case data
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        eventId = try values.decode(String.self, forKey: .eventId)
        appId = try values.decode(String.self, forKey: .appId)
        installationId = try values.decode(String.self, forKey: .installationId)
        appVersion = try values.decode(String.self, forKey: .appVersion)
        appBuildNumber = try values.decode(String.self, forKey: .appBuildNumber)
        sdkVersion = try values.decode(String.self, forKey: .sdkVersion)
        platform = try values.decode(String.self, forKey: .platform)
        osVersion = try values.decode(String.self, forKey: .osVersion)
        deviceManufacturer = try values.decode(String.self, forKey: .deviceManufacturer)
        deviceModel = try values.decode(String.self, forKey: .deviceModel)
        timestampOccurred = try values.decode(Date.self, forKey: .dtOccurred)
        isBeingFlushed = try values.decode(Bool.self, forKey: .isBeingFlushed)
        eventType = try values.decode(OmetriaEventType.self, forKey: .eventType)
        
        if values.contains(.data), let jsonData = try? values.decode(Data.self, forKey: .data) {
            data = (try? JSONSerialization.jsonObject(with: jsonData) as? [String : Any]) ?? [String:Any]()
        } else {
            data = [String:Any]()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !data.isEmpty, let jsonData = try? JSONSerialization.data(withJSONObject: data) {
            try container.encode(jsonData, forKey: .data)
        }
        try container.encode(eventId, forKey: .eventId)
        try container.encode(appId, forKey: .appId)
        try container.encode(installationId, forKey: .installationId)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(appBuildNumber, forKey: .appBuildNumber)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(platform, forKey: .platform)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(deviceManufacturer, forKey: .deviceManufacturer)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(timestampOccurred, forKey: .dtOccurred)
        try container.encode(isBeingFlushed, forKey: .isBeingFlushed)
        try container.encode(eventType, forKey: .eventType)
    }
    
    init(eventType: OmetriaEventType, data: [String: Any]) {
        self.eventId = UUID().uuidString
        self.eventType = eventType
        self.data = data
        
        let infoDict = Bundle.main.infoDictionary
        if let infoDict = infoDict {
            appBuildNumber = infoDict["CFBundleVersion"] as? String
            appVersion = infoDict["CFBundleShortVersionString"] as? String
        }
        sdkVersion = Constants.sdkVersion
    }
    
    // MARK: - CustomDebugStringConvertible
    
    var debugDescription: String {
        return "'\(eventType.id)'\n" +
        "   data: \(data)\n"
    }
    
    // MARK: - Dictionary
    
    var baseDictionary: [String: Any]? {
        let encoder = JSONEncoder.iso8601DateJSONEncoder
        guard let data = try? encoder.encode(self) else {
            return nil
        }
        let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return dictionary?.filter({
            ![.data,
              .eventId,
              .eventType,
              .dtOccurred].contains(CodingKeys(rawValue:$0.key))
        })
    }
    
    var dictionary: [String: Any]? {
        let encoder = JSONEncoder.iso8601DateJSONEncoder
        guard let encodedObject = try? encoder.encode(self) else {
            return nil
        }
        var dictionary = try? JSONSerialization.jsonObject(with: encodedObject, options: .allowFragments) as? [String: Any]
        if data.count != 0 {
            dictionary?[CodingKeys.data.rawValue] = data
        }
        
        return dictionary?.filter({
            [.data,
             .eventId,
             .eventType,
             .dtOccurred].contains(CodingKeys(rawValue:$0.key))
        })
    }
    
    // MARK: - Batching Hash
    
    var commonInfoHash: Int {
        var hasher = Hasher()
        hasher.combine(appId)
        hasher.combine(installationId)
        hasher.combine(appVersion)
        hasher.combine(appBuildNumber)
        hasher.combine(sdkVersion)
        hasher.combine(platform)
        hasher.combine(osVersion)
        hasher.combine(deviceManufacturer)
        hasher.combine(deviceModel)
        let hash = hasher.finalize()
        return hash
    }
}
