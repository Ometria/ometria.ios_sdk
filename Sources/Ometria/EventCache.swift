//
//  EventCache.swift
//  Ometria
//
//  Created by Catalin Demian on 11.04.2023.
//  Copyright © 2023 Cata. All rights reserved.
//

import Foundation

protocol EventCaching {
    func saveToFile(_ events: [OmetriaEvent]?)
    func saveToFile(_ events: [OmetriaEvent]?, async: Bool)
    func loadFromFile() -> [OmetriaEvent]?
}

extension EventCaching {
    func saveToFile(_ events: [OmetriaEvent]?) {
        self.saveToFile(events, async: true)
    }
}

class EventCache: EventCaching {
    let jsonCache: CodableCaching<[OmetriaEvent]>
    
    init(relativePathComponent: String) {
        jsonCache = JSONCache.trackedEvents(relativePath: relativePathComponent)
    }
    
    func saveToFile(_ events: [OmetriaEvent]?, async: Bool) {
        jsonCache.saveToFile(events, async: async)
    }
    
    func loadFromFile() -> [OmetriaEvent]? {
        return jsonCache.loadFromFile()
    }
}
