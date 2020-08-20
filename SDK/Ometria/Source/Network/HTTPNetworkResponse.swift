//
//  HTTPNetworkResponse.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}

//struct HTTPNetworkResponse {
//
//    // Properly checks and handles the status code of the response
//    static func handleNetworkResponse(for response: HTTPURLResponse?) -> Result<String>{
//
//        guard let res = response else { return Result.failure(HTTPNetworkError.UnwrappingError.rawValue)}
//
//        switch res.statusCode {
//        case 200...299: return Result.success(res.)
//        case 401: return Result.failure(HTTPNetworkError.authenticationError.rawValue)
//        case 400...499: return Result.failure(HTTPNetworkError.badRequest.rawValue)
//        case 500...599: return Result.failure(HTTPNetworkError.serverSideError.rawValue)
//        default: return Result.failure(HTTPNetworkError.failed.rawValue)
//        }
//    }
//}
