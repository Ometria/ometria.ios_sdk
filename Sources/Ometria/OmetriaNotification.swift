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
 
 - Parameter deepLinkActionUrl: The URL that was sent in the notification. We append tracking parameters to the URL specified in the account and campaign settings (these can be changed in the Ometria app)
 - Parameter imageUrl: The image URL that was sent in the notification.
 - Parameter campaignType: Can be trigger, mass, transactional (currently only trigger is used).
 - Parameter externalCustomerId: The id of the contact that was specified at customer creation (in the mobile app) or ingesting to Ometria.
 - Parameter sendId: Unique id of the message
 - Parameter tracking: An object that contains all tracking fields specified in the account and campaign settings (can be changed in the Ometria app, uses some defaults if not specified). It has the same values that we add to the deeplink url.
 */

public struct OmetriaNotification {
    
    var deepLinkActionUrl: String?
    var imageUrl: String?
    var externalCustomerId: String?
    var campaignType: String
    var sendId: String
    var tracking: [String:Any]
    
    public init(from dictionary: [String: Any]) throws {
        imageUrl = dictionary["imageUrl"] as? String
        deepLinkActionUrl = dictionary["deepLinkActionUrl"] as? String
        
        guard let context = dictionary["context"] as? [String: Any],
              let campaignType = context["campaign_type"] as? String,
              let sendId = context["send_id"] as? String
        else {
            throw OmetriaError.invalidNotificationContent(content: dictionary)
        }
        
        externalCustomerId = context["ext_customer_id"] as? String
        self.campaignType = campaignType
        self.sendId = sendId
        
        guard let tracking = context["tracking"] as? [String: Any] else {
            throw OmetriaError.invalidNotificationContent(content: dictionary)
        }
        
        self.tracking = tracking
    }
}
