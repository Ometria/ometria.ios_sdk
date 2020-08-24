//
//  EventsAPI.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

class EventsAPI {
    
    struct EventServiceConfig: NetworkServiceConfig {
        static var serverUrl = "https://mobile-events.ometria.com"
        static var httpHeaders: HTTPHeaders = [
            "X-Ometria-Auth": Ometria.sharedInstance().apiToken
        ]
        static var timeoutInterval: TimeInterval = 30
    }
    
    enum EventPath: String {
        case flush = "/v1/mobile-events"
        case flushValidate = "/v1/mobile-events/validate"
    }
    
    static let networkService = NetworkService<EventServiceConfig>()
    
    class func validateEvents(_ events: [OmetriaEvent], completion: @escaping ()->()) {
        var parameters = events.first!.baseDictionary
        parameters?["events"] = events.map({$0.dictionary})
        parameters?["timestampSent"] = ISO8601DateFormatter.ometriaDateFormatter.string(from: Date())
        do {
            try networkService.request(.post, path: EventPath.flushValidate.rawValue, parameters: parameters) { (result: Result<Any>) in
                switch result {
                case .failure(let error):
                    Logger.error(message: error.localizedDescription, category: .network)
                case .success(let response):
                    Logger.info(message: response, category: .network)
                }
            }
        }
        catch {
            Logger.error(message: error.localizedDescription, category: .network)
        }
    }
    
    class func flushEvents(_ events: [OmetriaEvent], completion: @escaping ()->()) {
        var parameters = events.first!.baseDictionary
        parameters?["events"] = events.map({$0.dictionary})
        parameters?["timestampSent"] = ISO8601DateFormatter.ometriaDateFormatter.string(from: Date())
        do {
            try networkService.request(.post, path: EventPath.flush.rawValue, parameters: parameters) { (result: Result<Any>) in
                switch result {
                case .failure(let error):
                    Logger.error(message: error.localizedDescription, category: .network)
                case .success(let response):
                    Logger.info(message: response, category: .network)
                }
            }
        }
        catch {
            Logger.error(message: error.localizedDescription, category: .network)
        }
    }
}
