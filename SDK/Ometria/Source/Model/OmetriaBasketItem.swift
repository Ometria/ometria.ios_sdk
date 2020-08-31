//
//  OmetriaBasketItem.swift
//  FirebaseCore
//
//  Created by Cata on 8/12/20.
//

import Foundation

open class OmetriaBasketItem: Codable {
    open var productId: String
    open var sku: String?
    open var quantity: Int
    open var price: Float
    
    public init(productId: String, sku: String? = nil, quantity: Int, price: Float) {
        self.productId = productId
        self.sku = sku
        self.quantity = quantity
        self.price = price
    }
}
