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
    case invalidNotificationContent(content: Any)
    case decodingFailed(underlyingError: Error)
    case encodingFailed(underlyingError: Error)
    
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
        case .encodingFailed(let underlyingError):
            return "Encoding failed with error: \(underlyingError.localizedDescription)"
        case .requestMissingURL:
            return "Network request failed because the url is missing."
        case .invalidNotificationContent(let content):
            return "The notification content has missing fields or is incorrectly formatted.\n\(content)"
        }
    }
    
    public var domain: String {
        return String(describing: Self.self)
    }
    
    public var type: String {
        return String(describing: self)
    }
    
    public var errorEventData: [String: Any] {
        var data: [String: Any] = [:]
        data["class"] = self.domain + "." + self.type
        data["message"] = self.localizedDescription
        
        if case .invalidNotificationContent(let content) = self {
            data["originalMessage"] = content
        }
        
        return data
    }
}
