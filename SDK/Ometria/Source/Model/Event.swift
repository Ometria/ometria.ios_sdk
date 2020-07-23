//
//  Event.swift
//  Ometria
//
//  Created by Cata on 7/22/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

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
            case .refreshPushToken: return "REFRESN_PUSH_TOKEN"
            case .receivedNotification: return "RECEIVED_NOTIFICATION"
            case .tapOnNotification: return "TAP_ON_NOTIFICATION"
            case .openDeepLink: return "OPEN_DEEP_LINK"
            case .custom(let customType): return customType
        }
    }
}

open class BaseEvent {
}

open class Event: BaseEvent {
    open var value: String?
    open var type: OmetriaEventType
    open var customTypeName: String
    open var params: [String: Any]
    private var creationDate = Date()
    private var isFlushed = false
    
    
    
    init(type: OmetriaEventType, value: String?) {
        self.type = type
    }
    
    func addParam(key: String, value: String) -> Event {
        params[key] = value
        return self
    }
    
    func setType(_ type: OmetriaEventType) -> Event {
        self.type = type
        return self
    }
}
