//
//  OmetriaBasketItem.swift
//  FirebaseCore
//
//  Created by Cata on 8/12/20.
//

import Foundation

open class OmetriaBasketItem: Codable {
    var productId: String
    var sku: String
    var quantity: Int
    var price: Float
    
    init(productId: String, sku: String, quantity: Int, price: Float) {
        self.productId = productId
        self.sku = sku
        self.quantity = quantity
        self.price = price
    }
}
