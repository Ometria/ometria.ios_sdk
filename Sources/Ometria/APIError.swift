//
//  HTTPError.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

public struct APIError: Error {
    var status: Int
    var type: String
    var title: String
    var detail: String
}


extension APIError: Decodable {
    private enum CodingKeys: String, CodingKey {
        case status, type, title, detail
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(Int.self, forKey: .status)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decode(String.self, forKey: .detail)
    }
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        return title + ": " + detail
    }
}
