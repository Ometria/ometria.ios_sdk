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
    case viewProduct
    case addProductToCart
    case removeProductFromCart
    case viewCart
    case startCheckout
    case completeOrder
    case addProductToWishlist
    case removeProductFromWishlist
    case addProductToCartFromWishlist
    
    // MARK: Application related event types
    case viewScreen
    case installApplication
    case launchApplication
    case bringApplicationToForeground
    case sendApplicationToBackground
    case identifyApplication
    case resetApplicationIdentification
    
    // MARK: Notification related event types
    case refreshPushToken
    case receivedNotification
    case tapOnNotification
    
    // MARK: Other event types
    case openDeepLink
    case custom(customType: String)
    
    var id: String {
        switch self {
            case .viewProduct: return "VIEW_PRODUCT"
            case .addProductToCart: return "ADD_PRODUCT_TO_CART"
            case .removeProductFromCart: return "REMOVE_PRODUCT_FROM_CART"
            case .viewCart: return "VIEW_CART"
            case .startCheckout: return "START_CHECKOUT"
            case .completeOrder: return "COMPLETE_ORDER"
            case .addProductToWishlist: return "ADD_PRODUCT_TO_WISHLIST"
            case .removeProductFromWishlist: return "REMOVE_PRODUCT_FROM_WISHLIST"
            case .addProductToCartFromWishlist: return "ADD_PRODUCT_TO_CART_FROM_WISHLIST"
            case .viewScreen: return "VIEW_SCREEN"
            case .installApplication: return "INSTALL_APPLICATION"
            case .launchApplication: return "LAUNCH_APPLICATION"
            case .bringApplicationToForeground: return "BRING_APPLICATION_TO_FOREGROUND"
            case .sendApplicationToBackground: return "SEND_APPLICATION_TO_BACKGROUND"
            case .identifyApplication: return "IDENTIFY_APPLICATION"
            case .resetApplicationIdentification: return "RESET_APPLICATION_IDENTIFICATION"
            case .refreshPushToken: return "REFRESN_PUSH_TOKEN"
            case .receivedNotification: return "RECEIVED_NOTIFICATION"
            case .tapOnNotification: return "TAP_ON_NOTIFICATION"
            case .openDeepLink: return "OPEN_DEEP_LINK"
            case .custom(let customType): return customType
        }
    }
}

class OmetriaEvent: BaseOmetriaEvent {
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
        super.init()
    }
    
    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public override var debugDescription: String {
        return super.debugDescription +
        "\(type.id):" +
        "   data: \(data)"
    }
}
