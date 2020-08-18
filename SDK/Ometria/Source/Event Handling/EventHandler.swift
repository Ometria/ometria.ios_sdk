
//
//  EventHandler.swift
//  Ometria
//
//  Created by Cata on 8/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

class EventHandler {
    
    func processEvent(type: OmetriaEventType, data: [String: Codable]) {
        let event = OmetriaEvent(eventType: type, data: data)
        Logger.info(message: "Process Event \(event)", category: LogCategory.events)
        
        let events = loadEventsFromCache()
        if var events = events {
            events.append(event)
            saveEventsToCache(events: events)
        }
        flushEventsIfNeeded()
    }
    
    func flushEventsIfNeeded() {
        if let events = loadEventsFromCache(), events.count > 1 {
            flushEvents()
        }
    }
    
    func flushEvents() {
        Logger.debug(message: "Flush Events", category: .events)
    }
    
    func loadEventsFromCache() -> [OmetriaEvent]? {
        Logger.debug(message: "Load events from local cache", category: .cache)
        return JSONCache.trackedEvents.loadFromFile()
    }
    
    func saveEventsToCache(events: [OmetriaEvent]) {
        Logger.debug(message: "Save events to local cache", category: .cache)
        JSONCache.trackedEvents.saveToFile(events)
    }
}
