//
//  OmetriaNotification.swift
//  Ometria
//
//  Created by Sergiu Corbu on 29.09.2021.
//  Copyright © 2021 Cata. All rights reserved.
//

import Foundation

/**
 An object representing a notification.
 
 - Parameter deepLink: The URL that was sent in the notification. We append tracking parameters to the URL specified in the account and campaign settings (these can be changed in the Ometria app)
 - Parameter imageUrl: The image URL that was sent in the notification.
 - Parameter campaign_type: Can be trigger, mass, transactional (currently only trigger is used).
 - Parameter externalCustomerId: The id of the contact that was specified at customer creation (in the mobile app) or ingesting to Ometria.
 - Parameter sendId: Unique id of the message
 - Parameter tracking: An object that contains all tracking fields specified in the account and campaign settings (can be changed in the Ometria app, uses some defaults if not specified). It has the same values that we add to the deeplink url.
 */

public struct OmetriaNotification: Decodable {
    
    public var deepLink: String?
    public var imageUrl: String?
    public var externalCustomerId: String?
    public var campaignType: String?
    public var sendId: String?
    public var tracking: [String:Any]?
    
    enum CodingKeys: String, CodingKey {
        case externalCustomerId = "ext_customer_id"
        case deepLink = "deepLinkActionUrl"
        case imageUrl
        case context
    }
    
    enum TrackingKeys: CodingKey {
        case tracking
    }
    
    enum ContextKeys: String, CodingKey {
        case campaignType = "campaign_type"
        case sendId = "send_id"
        case tracking
    }
    
    public init(from decoder: Decoder) throws {
        let valuesContainer = try decoder.container(keyedBy: CodingKeys.self)
        deepLink = try? valuesContainer.decode(String.self, forKey: .deepLink)
        imageUrl = try? valuesContainer.decode(String.self, forKey: .imageUrl)
        externalCustomerId = try? valuesContainer.decode(String.self, forKey: .externalCustomerId)
        
        let contextContainer = try valuesContainer.nestedContainer(keyedBy: ContextKeys.self, forKey: .context)
        campaignType = try? contextContainer.decode(String.self, forKey: .campaignType)
        sendId = try? contextContainer.decode(String.self, forKey: .sendId)
        
        guard contextContainer.contains(.tracking),
              let jsonData = try? contextContainer.decode(Data.self, forKey: .tracking) else {
                  tracking = [:]
                  return
        }
        tracking = (try? JSONSerialization.jsonObject(with: jsonData) as? [String : Any]) ?? [String:Any]()
    }
}
