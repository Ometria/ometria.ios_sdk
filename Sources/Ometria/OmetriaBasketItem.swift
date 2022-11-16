//
//  OmetriaBasketItem.swift
//  FirebaseCore
//
//  Created by Cata on 8/12/20.
//

import Foundation

/**
 An object representing one entry of a particular item in a basket. It can have its own price and quantity based on different rules and promotions that are being applied.
 
 - Parameter productId: A string representing the unique identifier of this product.
 - Parameter variantId: A string representing the variant identifier of this product
 - Parameter sku: A string representing the stock keeping unit, which allows identifying a particular item.
 - Parameter quantity: The number of items that this entry represents.
 - Parameter price: Float value representing the price for one item. The currency is established by the OmetriaBasket containing this item
 */
open class OmetriaBasketItem: Codable, Equatable {
    
    var productId: String
    var variantId: String?
    var sku: String?
    var quantity: Int
    var price: Float
    
    public init(productId: String, variantId: String? = nil, sku: String? = nil, quantity: Int, price: Float) {
        self.productId = productId
        self.variantId = variantId
        self.sku = sku
        self.quantity = quantity
        self.price = price
    }
    
    public static func == (lhs: OmetriaBasketItem, rhs: OmetriaBasketItem) -> Bool {
        return lhs.productId == rhs.productId
    }
}
