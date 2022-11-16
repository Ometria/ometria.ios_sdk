//
//  OmetriaBasket.swift
//  FirebaseCore
//
//  Created by Cata on 8/12/20.
//

import Foundation

/**
 An object that describes the contents of a shopping basket.
 
 - Parameter id: A string representing the identifier of the basket object.
 - Parameter currency: A string representing the currency in ISO currency format. e.g. "USD", "GBP"
 - Parameter price: A float value representing the pricing.
 - Parameter items: An array containing the item entries in this basket.
 - Parameter link: A deeplink to the web or in-app page for this basket. Can be used in a notification sent to the user, e.g. "Forgot to check out? Here's your basket to continue: ". Following that link should take them straight to the basket page.
 */
open class OmetriaBasket: Codable {
    var id: String?
    var currency: String
    var totalPrice: Float
    var items: [OmetriaBasketItem] = []
    var link: String?
    
    public init(id: String? = nil, totalPrice: Float, currency: String, items: [OmetriaBasketItem] = [], link: String? = nil) {
        self.id = id
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
