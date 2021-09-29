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

open class OmetriaNotification: Decodable {
    
    open var deepLinkActionUrl: String
    open var imageUrl: String
    open var context: Context
    
    enum CodingKeys: String, CodingKey {
        case deepLinkActionUrl
        case imageUrl
        case context
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        deepLinkActionUrl = try values.decode(String.self, forKey: .deepLinkActionUrl)
        imageUrl = try values.decode(String.self, forKey: .imageUrl)
        context = try values.decode(Context.self, forKey: .context)
    }
    
    
    public struct Context: Decodable {
        
        var campaign_type: String
        var ext_customer_id: String
        var app_install_id: String
        var campaign_hash: String
        var campaing_id: String
        var mobile_app_id: String
        var om_customer_id: String
        var account_id: String
        var campaign_version: String
        var node_id: String
        var send_id: String
        var tracking: [String:Any]
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case campaign_type
            case ext_customer_id
            case tracking
            case app_install_id
            case campaign_hash
            case campaing_id
            case mobile_app_id
            case om_customer_id
            case account_id
            case campaign_version
            case node_id
            case send_id
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            campaign_type = try values.decode(String.self, forKey: .campaign_type)
            ext_customer_id = try values.decode(String.self, forKey: .ext_customer_id)
            app_install_id = try values.decode(String.self, forKey: .app_install_id)
            campaign_hash = try values.decode(String.self, forKey: .campaign_hash)
            campaing_id = try values.decode(String.self, forKey: .campaing_id)
            campaign_version = try values.decode(String.self, forKey: .campaign_version)
            mobile_app_id = try values.decode(String.self, forKey: .mobile_app_id)
            om_customer_id = try values.decode(String.self, forKey: .om_customer_id)
            node_id = try values.decode(String.self, forKey: .node_id)
            send_id = try values.decode(String.self, forKey: .send_id)
            account_id = try values.decode(String.self, forKey: .account_id)

            guard values.contains(.tracking),
                  let jsonData = try? values.decode(Data.self, forKey: .tracking) else {
                      tracking = [:]
                      return
            }
            tracking = (try? JSONSerialization.jsonObject(with: jsonData) as? [String : Any]) ?? [String:Any]()
        }
    }
    
}
