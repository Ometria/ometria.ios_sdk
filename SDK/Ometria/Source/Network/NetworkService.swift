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
    let urlSession = URLSession(configuration: .default)
    
    @discardableResult
    func request(_ method: HTTPMethod,
                 path: String,
                 parameters: HTTPParams = nil,
                 headers: HTTPHeaders = nil,
                 completion: @escaping (_ result: Result<String>) -> ()) throws -> URLSessionTask
    {
        let url = URL(string: Config.serverUrl)!.appendingPathComponent(path)
        
        // append http headers
        var mutableHeaders : [String : Any] = headers ?? [:]
        for (k, v) in Config.httpHeaders ?? [:] {
            mutableHeaders.updateValue(v, forKey: k)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        do {
            request = try URLParamEncoder().encodeHeaders(request, with: mutableHeaders)
            request = try JSONParamEncoder(writingOptions: .fragmentsAllowed).encode(request, with: parameters)
        } catch {
            print(error)
        }
        request.timeoutInterval = 30.0;//seconds
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            print(data)
        }
        dataTask.resume()
        return dataTask
    }
    
//    public static func apiErrorResponseSerializer() -> DataResponseSerializer<()> {
//        return DataResponseSerializer { request, response, data, error in
//
//            var apiError = error
//            if let data = data {
//                do {
//                    apiError = try JSONDecoder().decode(APIError.self, from: data)
//                } catch DecodingError.dataCorrupted(let context) {
//                    print(context.debugDescription)
//                } catch DecodingError.keyNotFound(let key, let context) {
//                    //No error
//                    print("\(key.stringValue) was not found, \(context.debugDescription)")
//                } catch DecodingError.typeMismatch(let type, let context) {
//                    print("\(type) was expected, \(context.debugDescription)")
//                } catch DecodingError.valueNotFound(let type, let context) {
//                    print("no value was found for \(type), \(context.debugDescription)")
//                } catch {
//                    print("Unknown error")
//                }
//            }
//
//            guard apiError == nil else {
//                print("\n❗ Request failed: ",
//                      request?.httpMethod ?? "",
//                      request?.url?.absoluteString ?? "",
//                      "\n\tResponse: " + (data.flatMap({ String(data:$0, encoding: .utf8) }) ?? ""))
//
//
//                let missingSession = apiError == .missingSession
//                let accessDenied = response?.statusCode == 403 || response?.statusCode == 401 || missingSession
//                if accessDenied {
//                    DispatchQueue.main.async {
//                        Session.close(error: apiError!)
//                    }
//                }
//
//                return .failure(apiError!)
//            }
//
//            return .success(())
//        }
//    }
//
//    public func responseAPIDecode<T: Decodable>(decoder: JSONDecoder = JSONDecoder(), keyPath: String? = nil,
//                                                completion: @escaping (DataResponse<T>, Tapptitude.Result<T>) -> ()) -> Self {
//        let serializer: DataResponseSerializer<T> = DataRequest.apiDecodableSerializer(decoder: decoder, keyPath: keyPath)
//        return validate().response(queue: nil, responseSerializer: serializer, completionHandler: { response in
//            if !self.responseWasCanceled(response) {
//                let result: Tapptitude.Result<T> = response.result.map({ $0 })
//                completion(response, result)
//            }
//        })
//    }
//
//    public static func apiDecodableSerializer<T: Decodable>(decoder: JSONDecoder, keyPath: String? = nil) -> DataResponseSerializer<T> {
//        return DataResponseSerializer { request, response, data, error in
//            let result = apiErrorResponseSerializer().serializeResponse(request, response, data, error)
//            switch result {
//            case .success(_):
//                do {
//                    var object:T
//                    if let keyPath = keyPath {
//                        object = try decoder.decode(T.self, from: data!, keyPath: keyPath, separator: ".")
//                    } else {
//                        object = try decoder.decode(T.self, from: data!)
//                    }
//                    return .success(object)
//                }
//                catch {
//                    return .failure(error)
//                }
//            case .failure(let error):
//                return .failure(error)
//            }
//        }
//    }
}
