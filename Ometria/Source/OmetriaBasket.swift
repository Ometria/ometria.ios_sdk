//
//  OmetriaBasket.swift
//  FirebaseCore
//
//  Created by Cata on 8/12/20.
//

import Foundation

/**
 An object that describes the contents of a shopping basket.
 
 - Parameter currency: A string representing the currency in ISO currency format. e.g. "USD", "GBP"
 - Parameter price: A float value representing the pricing.
 - Parameter items: An array containing the item entries in this basket.
 */
open class OmetriaBasket: Codable {
    open var currency: String
    open var totalPrice: Float
    open var items: [OmetriaBasketItem] = []
    
    public init(totalPrice: Float, currency: String, items: [OmetriaBasketItem] = []) {
        self.currency = currency
        self.totalPrice = totalPrice
        self.items = items
    }
 
    func jsonObject() throws -> Any {
        let basketData = try JSONEncoder().encode(self)
        let serializedBasket = try JSONSerialization.jsonObject(with: basketData, options: .allowFragments)
        return serializedBasket
    }
}
