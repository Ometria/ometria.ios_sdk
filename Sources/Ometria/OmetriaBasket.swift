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
 - Parameter link: A deeplink to the web or in-app page for this basket. Can be used in a notification sent to the user, e.g. "Forgot to check out? Here's your basket to continue: ". Following that link should take them straight to the basket page.
 */
open class OmetriaBasket: Codable {
    open var currency: String
    open var totalPrice: Float
    open var items: [OmetriaBasketItem] = []
    open var link: String?
    
    public init(totalPrice: Float, currency: String, items: [OmetriaBasketItem] = [], link: String? = nil) {
        self.currency = currency
        self.totalPrice = totalPrice
        self.items = items
        self.link = link
    }
 
    func jsonObject() throws -> Any {
        let basketData = try JSONEncoder().encode(self)
        let serializedBasket = try JSONSerialization.jsonObject(with: basketData, options: .allowFragments)
        return serializedBasket
    }
}
