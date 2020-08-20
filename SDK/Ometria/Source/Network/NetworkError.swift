//
//  HTTPError.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

struct NetworkError: Error {
    var code: Int
    var message: String
}


extension NetworkError: Decodable {
    private enum CodingKeys: String, CodingKey {
        case code, message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
    }
}

extension NetworkError: LocalizedError {
    var localizedDescription: String {
        return message
    }
}
