//
//  OmetriaBasket.swift
//  FirebaseCore
//
//  Created by Cata on 8/12/20.
//

import Foundation

open class OmetriaBasket: Encodable {
    var currency: String
    var totalPrice: Float
    var items: [OmetriaBasketItem] = []
    
    init(totalPrice: Float, currency: String, items: [OmetriaBasketItem] = []) {
        self.currency = currency
        self.totalPrice = totalPrice
        self.items = items
    }
    
}
