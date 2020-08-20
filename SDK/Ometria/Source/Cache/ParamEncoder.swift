//
//  ParamEncoder.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

protocol ParamEncoder {
    func encode(_ urlRequest: URLRequest, with parameters: HTTPParams) throws -> URLRequest
}

protocol HeaderEncoder {
    func encodeHeaders(_ urlRequest: URLRequest, with headers: HTTPHeaders) throws -> URLRequest
}

public struct JSONParamEncoder: ParamEncoder {
    
    var writingOptions: JSONSerialization.WritingOptions
    
    init(writingOptions: JSONSerialization.WritingOptions) {
        self.writingOptions = writingOptions
    }
    
    func encode(_ urlRequest: URLRequest, with parameters: HTTPParams) throws -> URLRequest {
        guard let parameters = parameters else {
            return urlRequest
        }
        
        var mutableRequest = urlRequest

        let data = try JSONSerialization.data(withJSONObject: parameters, options: writingOptions)
        
        if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        mutableRequest.httpBody = data

        return mutableRequest
    }
    
}

public struct URLParamEncoder: ParamEncoder, HeaderEncoder {
    func encode(_ urlRequest: URLRequest, with parameters: HTTPParams) throws -> URLRequest {
        if parameters == nil {
            return urlRequest
        }
        
        var mutableRequest = urlRequest
        guard let url = mutableRequest.url, let unwrappedParameters = parameters else {
            throw OmetriaError.requestMissingURL
        }
        
        
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !unwrappedParameters.isEmpty {
            urlComponents.queryItems = [URLQueryItem]()
            
            for (key,value) in unwrappedParameters {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                
                urlComponents.queryItems?.append(queryItem)
            }
            
            mutableRequest.url = urlComponents.url
        }
        
        return mutableRequest
    }
    
    func encodeHeaders(_ urlRequest: URLRequest, with headers: HTTPHeaders) throws -> URLRequest {
        guard let unwrappedHeaders = headers else {
            return urlRequest
        }
        
        var mutableRequest = urlRequest
        for (key, value) in unwrappedHeaders {
            var finalValue = value as? String
            if value is CustomStringConvertible {
                finalValue = String(describing: value)
            }
                
            mutableRequest.setValue(finalValue, forHTTPHeaderField: key)
        }
        return mutableRequest
    }
}
