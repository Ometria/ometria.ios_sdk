
//
//  EventHandler.swift
//  Ometria
//
//  Created by Cata on 8/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

class EventHandler {
    
    private var trackedEvents: [OmetriaEvent] = []
    private var hasLoadedEvents: Bool = false
    
    func processEvent(type: OmetriaEventType, data: [String: Codable]) {
        let event = OmetriaEvent(eventType: type, data: data)
        Logger.info(message: "Process Event \(event)", category: LogCategory.events)
        
        saveEvent(event: event)
        flushEventsIfNeeded()
    }
    
    func flushEventsIfNeeded() {
        let events = retrieveEvents()
        if events.count > 1 {
            flushEvents()
        }
    }
    
    func flushEvents() {
        Logger.debug(message: "Flush Events", category: .events)
        let events = retrieveEvents()
        EventsAPI.flushEvents(events, completion: { () in
            
        })
    }
    
    func clearEvents() {
        Logger.debug(message: "Clear all Events", category: .events)
        trackedEvents.removeAll()
        JSONCache.trackedEvents.saveToFile(nil, async: true)
    }
    
    func retrieveEvents() -> [OmetriaEvent] {
        if !hasLoadedEvents {
            Logger.debug(message: "Load Events from local cache", category: .cache)
            if let cachedEvents = JSONCache.trackedEvents.loadFromFile() {
                trackedEvents = cachedEvents
            }
        }
        return trackedEvents
    }
    
    func saveEvent(event: OmetriaEvent) {
        Logger.debug(message: "Save Events to local cache", category: .cache)
        var events = retrieveEvents()
        events.append(event)
        trackedEvents = events
        JSONCache.trackedEvents.saveToFile(events, async: true)
    }
    
    // MARK: - Event Batching
    
    
}
