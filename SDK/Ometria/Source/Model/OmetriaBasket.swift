//
//  OmetriaBasket.swift
//  FirebaseCore
//
//  Created by Cata on 8/12/20.
//

import Foundation

open class OmetriaBasket: Codable {
    open var currency: String
    open var totalPrice: Float
    open var items: [OmetriaBasketItem] = []
    
    public init(totalPrice: Float, currency: String, items: [OmetriaBasketItem] = []) {
        self.currency = currency
        self.totalPrice = totalPrice
        self.items = items
    }
    
}
