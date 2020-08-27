//
//  OmetriaError.swift
//  FirebaseCore
//
//  Created by Cata on 8/19/20.
//

import Foundation

public enum OmetriaError: Error {
    case parameterEncodingFailed
    case apiError(underlyingError: APIError)
    case invalidAPIResponse
    case invalidNotificationBody(content: Any)
    case decodingFailed(underlyingError: Error)
    
    case requestMissingURL
}

extension OmetriaError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .parameterEncodingFailed:
            return "Failed to encode request parameters."
        case .apiError(let underlyingError):
            return "Network request failed with error: \(underlyingError.localizedDescription)"
        case .invalidAPIResponse:
            return "Network request failed because it was unable to process the server response."
        case .decodingFailed(let underlyingError):
            return "Decoding failed with error: \(underlyingError.localizedDescription)"
        case .requestMissingURL:
            return "Network request failed because the url is missing."
        case .invalidNotificationBody(let content):
            return "The notification body had missing fields or was incorrectly formatted.\n\(content)"
        }
    }
}
