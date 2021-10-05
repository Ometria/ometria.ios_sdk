//
//  Decodable+Serialization.swift
//  Ometria
//
//  Created by Sergiu Corbu on 29.09.2021.
//  Copyright © 2021 Cata. All rights reserved.
//

import Foundation

extension Decodable {
    
    init(from: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: from, options: .prettyPrinted)
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}
