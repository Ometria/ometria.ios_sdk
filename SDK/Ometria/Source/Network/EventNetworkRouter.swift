//
//  EventsAPI.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

class EventNetworkRouter {
    enum EventPath: String {
        case flush = "/v1/mobile-events/"
        case flushValidate = "/v1/mobile-events/validate"
    }
    
    struct EventsServiceConfig: NetworkServiceConfig {
        static var serverUrl = "https://mobile-events.ometria.com"
        static var httpHeaders: HTTPHeaders = [
            "X-Ometria-Auth": "validation-only-test-key"
        ]
        static var timeoutInterval: TimeInterval = 30
    }
    static let networkService = NetworkService<EventsServiceConfig>()
    
    class func flushEvents(_ events: [OmetriaEvent], completion: @escaping ()->()) {
        var parameters = events.first!.baseDictionary
        parameters?["events"] = events.map({$0.dictionary})
        parameters?["timestampSent"] = ISO8601DateFormatter.ometriaDateFormatter.string(from: Date())
        do {
            let dataTask = try networkService.request(.post, path: EventPath.flushValidate.rawValue, parameters: parameters) { (result) in
                
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
