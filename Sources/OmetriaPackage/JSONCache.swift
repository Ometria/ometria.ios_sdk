//
//  JSONCache.swift
//  Ometria
//
//  Created by Cata on 8/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

/// Usage Ex:
/// - loading -- `lazy var creditCards: [CreditCard]? = JSONCache.creditCards.loadFromFile()`
/// - saving -- `JSONCache.creditCards.saveToFile(cards)`
enum JSONCache {
    
    static var trackedEvents: CodableCaching<[OmetriaEvent]> {
        return cachedResource()
    }
    
    static func clearAllSavedResource() {
        CodableCaching<Any>.deleteCachingDirectory()
    }
}

extension JSONCache {
    fileprivate static func cachedResource<T>(name: String = #function) -> CodableCaching<T> {
        return CodableCaching(resourceID: name)
    }
}

