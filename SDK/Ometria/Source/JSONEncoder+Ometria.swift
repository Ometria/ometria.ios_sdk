//
//  JSONEncoder+Ometria.swift
//  Ometria
//
//  Created by Cata on 8/20/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

extension JSONEncoder {
    static var iso8601DateJSONEncoder = { () -> JSONEncoder in
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = DateEncodingStrategy.custom({ (date, encoder) in
            let formatter = ISO8601DateFormatter.ometriaDateFormatter
            let dateString = formatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        })
        return encoder
    }()
    
}
