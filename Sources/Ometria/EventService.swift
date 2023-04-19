//
//  EventService.swift
//  Ometria
//
//  Created by Catalin Demian on 11.04.2023.
//  Copyright © 2023 Cata. All rights reserved.
//

import Foundation

struct EventServiceConfig: NetworkServiceConfig {
    static var serverUrl = "https://mobile-events.ometria.com"
    static var httpHeaders: HTTPHeaders = [
        "X-Ometria-Auth": Ometria.sharedInstance().apiToken
    ]
    static var timeoutInterval: TimeInterval = 30
}

protocol EventServiceProtocol {
    func validateEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>)->())
    func flushEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>)->())
}

struct EventService: EventServiceProtocol {
    enum EventPath: String {
        case flush = "/v1/mobile-events"
        case flushValidate = "/v1/mobile-events/validate"
    }
    
    var networkService: NetworkService = NetworkService<EventServiceConfig>()
    
    init(networkService: NetworkService<EventServiceConfig> = NetworkService<EventServiceConfig>()) {
        self.networkService = networkService
    }
    
    func validateEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>)->()) {
         var parameters = events.first!.baseDictionary ?? [:]
        parameters["events"] = events.compactMap({$0.dictionary})
        parameters["dtSent"] = ISO8601DateFormatter.ometriaDateFormatter.string(from: Date())
        
        do {
            try networkService.request(.post, path: EventPath.flushValidate.rawValue, parameters: parameters) { (result: Result<Any>) in
                switch result {
                
                case .failure(let error):
                    Logger.error(message: error.localizedDescription, category: .network)
                
                case .success(let response):
                    Logger.info(message: response, category: .network)
                }
                
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
        catch {
            Logger.error(message: error.localizedDescription, category: .network)
        }
    }
    
    func flushEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>)->()) {
        var parameters = events.first!.baseDictionary ?? [:]
        parameters["events"] = events.compactMap({$0.dictionary})
        parameters["dtSent"] = ISO8601DateFormatter.ometriaDateFormatter.string(from: Date())
        
        Logger.debug(message: "Performing flush with parameters:", category: .network)
        Logger.debug(message: parameters as Any, category: .network)
        
        do {
            try networkService.request(.post, path: EventPath.flush.rawValue, parameters: parameters) { (result: Result<Any>) in
                switch result {
                    
                case .failure(let error):
                    Logger.error(message: error.localizedDescription, category: .network)
                    
                case .success(let response):
                    Logger.verbose(message: "Server response: \(response)", category: .network)
                    break
                }
                
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
        catch {
            Logger.error(message: error.localizedDescription, category: .network)
        }
    }
}
