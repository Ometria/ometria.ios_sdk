//
//  NetworkService.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

typealias HTTPHeaders = [String: Any]?
typealias HTTPParams = [String: Any]?

public enum HTTPMethod: String{
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol NetworkServiceConfig {
    static var serverUrl: String { get }
    static var httpHeaders: HTTPHeaders { get }
    static var timeoutInterval: TimeInterval { get }
}

class NetworkService<Config: NetworkServiceConfig> {
    
    fileprivate var acceptableStatusCodes: [Int] { return Array(200..<300) }
    fileprivate var acceptableContentTypes: [String] { return ["*/*"] }
    private let urlSession = URLSession(configuration: .default)
    
    @discardableResult
    func request(_ method: HTTPMethod,
                 path: String,
                 parameters: HTTPParams = nil,
                 headers: HTTPHeaders = nil,
                 completion: @escaping (_ result: Result<Any>) -> ()) throws -> URLSessionTask
    {
        let url = URL(string: Config.serverUrl)!.appendingPathComponent(path)
        
        // append http headers
        var mutableHeaders : [String : Any] = headers ?? [:]
        for (k, v) in Config.httpHeaders ?? [:] {
            mutableHeaders.updateValue(v, forKey: k)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request = try URLParamEncoder().encodeHeaders(request, with: mutableHeaders)
        request = try JSONParamEncoder(writingOptions: .fragmentsAllowed).encode(request, with: parameters)
        request.timeoutInterval = Config.timeoutInterval
        
        let dataTask = urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else {
                return
            }
            
            let validationResult = self.validate(data: data, response: response, error: error)
            switch validationResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(_):
                let serializationResult = self.serializeJSONResponse(data: data!, response: response as! HTTPURLResponse)
                completion(serializationResult)
            }
        }
        dataTask.resume()
        return dataTask
    }
    
    private func validate(data: Data?, response: URLResponse?, error: Error?) -> Result<Void> {
        guard error == nil else {
            return .failure(error!)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(OmetriaError.invalidAPIResponse)
        }
        
        guard acceptableStatusCodes.contains(httpResponse.statusCode) else {
            let error = serializeErrorResponse(data: data, response: httpResponse)
            return .failure(error)
        }
        
        return .success()
    }
    
    private func serializeErrorResponse(data: Data?, response: HTTPURLResponse) -> Error {
        
        var apiError: OmetriaError? = nil
        if let data = data {
            do {
                let error = try JSONDecoder().decode(APIError.self, from: data)
                apiError = .apiError(underlyingError: error)
            } catch {
                apiError = OmetriaError.decodingFailed(underlyingError: error)
            }
        } else {
            let underlyingError = APIError(status: response.statusCode, type: "Unkown", title: "Unknown Error", detail: "Error details were not provided by server.")
            apiError = .apiError(underlyingError: underlyingError)
        }
        
        return apiError!
    }
    
    private func serializeDataResponse<T: Decodable>(data: Data, response: HTTPURLResponse) -> Result<T> {
        do {
            let object:T = try JSONDecoder().decode(T.self, from: data)
            return .success(object)
        }
        catch {
            let apiError = OmetriaError.decodingFailed(underlyingError: error)
            return .failure(apiError)
        }
    }
    
    private func serializeJSONResponse(data: Data, response: HTTPURLResponse) -> Result<Any> {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            return .success(json)
        } catch {
            return .failure(OmetriaError.decodingFailed(underlyingError: error))
        }
    }
}
