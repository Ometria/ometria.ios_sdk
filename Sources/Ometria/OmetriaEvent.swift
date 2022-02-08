//
//  OmetriaEvent.swift
//  Ometria
//
//  Created by Cata on 7/22/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

enum OmetriaEventType: String, Codable, CaseIterable {
    
    // MARK: Product related event types
    case basketUpdated
    case basketViewed
    case checkoutStarted
    case orderCompleted
    case productListingViewed
    case productViewed
    case wishlistAddedTo
    case wishlistRemovedFrom
    
    // MARK: Application related event types
    case appInstalled
    case appLaunched
    case appBackgrounded
    case appForegrounded
    case homeScreenViewed
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
    case custom = "customEvent"
    case errorOccurred
}

class OmetriaEvent: CustomDebugStringConvertible, Codable {
    var eventId: String
    var appId = Bundle.main.bundleIdentifier ?? "unknown"
    var installationId = OmetriaDefaults.installationID ?? "unknown"
    var appVersion: String?
    var appBuildNumber: String?
    var sdkVersion: String
    var sdkVersionRN: String?
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
        case sdkVersionRN
        case platform
        case osVersion
        case deviceManufacturer
        case deviceModel
        case dtOccurred
        
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
        sdkVersionRN = try values.decode(String.self, forKey: .sdkVersionRN)
        platform = try values.decode(String.self, forKey: .platform)
        osVersion = try values.decode(String.self, forKey: .osVersion)
        deviceManufacturer = try values.decode(String.self, forKey: .deviceManufacturer)
        deviceModel = try values.decode(String.self, forKey: .deviceModel)
        timestampOccurred = try values.decode(Date.self, forKey: .dtOccurred)
        eventType = try values.decode(OmetriaEventType.self, forKey: .eventType)
        
        if values.contains(.data), let jsonData = try? values.decode(Data.self, forKey: .data) {
            data = (try? JSONSerialization.jsonObject(with: jsonData) as? [String : Any]) ?? [String:Any]()
        } else {
            data = [String:Any]()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !data.isEmpty {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try container.encode(jsonData, forKey: .data)
        }
        try container.encode(eventId, forKey: .eventId)
        try container.encode(appId, forKey: .appId)
        try container.encode(installationId, forKey: .installationId)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(appBuildNumber, forKey: .appBuildNumber)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(sdkVersionRN, forKey: .sdkVersionRN)
        try container.encode(platform, forKey: .platform)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(deviceManufacturer, forKey: .deviceManufacturer)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(timestampOccurred, forKey: .dtOccurred)
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
        sdkVersionRN = OmetriaDefaults.sdkVersionRN
    }
    
    // MARK: - CustomDebugStringConvertible
    
    var debugDescription: String {
        return "'\(eventType.rawValue)'\n" +
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
