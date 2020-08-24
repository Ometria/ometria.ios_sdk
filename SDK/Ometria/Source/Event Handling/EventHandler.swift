
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
    var flushLimit: Int
    
    init(flushLimit: Int) {
        self.flushLimit = flushLimit
    }
    
    func processEvent(type: OmetriaEventType, data: [String: Codable]) {
        let event = OmetriaEvent(eventType: type, data: data)
        
        Logger.info(message: "Process Event \(event)", category: LogCategory.events)
        saveEvent(event)
        flushEventsIfNeeded()
    }
    
    func flushEventsIfNeeded() {
        let events = retrieveFlushableEvents()
        
        print("flushable events: \(events.count)")
        if events.count >= flushLimit {
            flushEvents()
        }
    }
    
    func flushEvents() {
        let events = retrieveFlushableEvents()
        guard events.count != 0 else {
            return
        }
        
        let batchedEvents = batchEvents(events: events)
        
        for key in batchedEvents.keys {
            let batch = batchedEvents[key]!
            let flushSizedChunks = batch.chunked(into: flushLimit)
            for chunk in flushSizedChunks {
                flushEvents(events: chunk)
            }
        }
    }
    
    private func flushEvents(events: [OmetriaEvent]) {
        Logger.debug(message: "Begin flushing \(events.count) events.", category: .events)
        events.forEach({$0.isBeingFlushed = true})
        let flushableEvents = retrieveFlushableEvents()
        print("flushable events: \(flushableEvents.count)")
        EventsAPI.flushEvents(events) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            
            case .success(_):
                Logger.debug(message: "Successfully flushed \(events.count) events.", category: .events)
                self.removeEvents(events)
            case .failure(_):
                Logger.debug(message: "Failed to flush \(events.count) events.", category: .events)
                events.forEach({$0.isBeingFlushed = false})
                self.saveMemoryCachedEvents()
            }
        }
    }
    
    // MARK: - Cache accessibility
    
    func clearEvents() {
        Logger.verbose(message: "Clear all Events from local cache.", category: .events)
        trackedEvents.removeAll()
        JSONCache.trackedEvents.saveToFile(nil, async: true)
    }
    
    private func retrieveEvents() -> [OmetriaEvent] {
        if !hasLoadedEvents {
            Logger.verbose(message: "Load Events from local cache", category: .cache)
            
            if let cachedEvents = JSONCache.trackedEvents.loadFromFile() {
                hasLoadedEvents = true
                trackedEvents = cachedEvents
            }
        }
        return trackedEvents
    }
    
    private func retrieveFlushableEvents() -> [OmetriaEvent] {
        let events = retrieveEvents()
        return events.filter({ !$0.isBeingFlushed })
    }
    
    private func saveMemoryCachedEvents() {
        let events = retrieveEvents()
       
        saveEvents(events)
    }
    
    private func saveEvent(_ event: OmetriaEvent) {
        var events = retrieveEvents()
        
        events.append(event)
        saveEvents(events)
    }
    
    private func saveEvents(_ events: [OmetriaEvent]) {
        Logger.verbose(message: "Save Events to local cache", category: .cache)
        trackedEvents = events
        JSONCache.trackedEvents.saveToFile(events, async: true)
    }
    
    private func removeEvents(_ events: [OmetriaEvent]) {
        let eventIds = events.map({$0.eventId})
        var savedEvents = retrieveEvents()
        
        savedEvents.removeAll(where: { eventIds.contains($0.eventId) })
        saveEvents(savedEvents)
    }
    
    // MARK: - Event Batching
    
    private func batchEvents(events: [OmetriaEvent]) -> [Int: [OmetriaEvent]] {
        let batchedEvents = Dictionary.init(grouping: events, by: { $0.commonInfoHash })
        
        return batchedEvents
    }
}
