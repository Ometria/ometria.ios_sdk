//
//  OmetriaNotificationBody.swift
//  FirebaseCore
//
//  Created by Cata on 8/27/20.
//

import Foundation

struct OmetriaNotificationBody {
    var context: [String: Any]
    var imageURL: String?
    var deepLinkActionURL: String?
    
    init(from dictionary: [String: Any]) throws {
        guard let context = dictionary["context"] as? [String: Any] else {
            throw OmetriaError.invalidNotificationContent(content: dictionary)
        }
        
        self.context = context
        self.imageURL = dictionary["imageUrl"] as? String
        self.deepLinkActionURL = dictionary["deepLinkActionUrl"] as? String
    }
}
