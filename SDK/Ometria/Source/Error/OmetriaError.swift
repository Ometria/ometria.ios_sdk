//
//  OmetriaError.swift
//  FirebaseCore
//
//  Created by Cata on 8/19/20.
//

import Foundation

public enum OmetriaError: Error {
    case networkParamEncoding
    case networkError(code: Int, message: String)
    case requestMissingURL
}
