
//
//  EventHandler.swift
//  Ometria
//
//  Created by Cata on 8/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

class EventHandler {
    
    private var eventsQueue: DispatchQueue
//    private var memoryCacheLock: ReadWriteLock = ReadWriteLock(label: "com.ometria.eventsMemoryCacheLock")
    private var trackedEvents: [OmetriaEvent] = []
    private var hasLoadedEvents: Bool = false
    private var dropStatusCodes: [Int] = {
        var retryCodes = Array(400..<500)
        retryCodes.removeAll { (value) -> Bool in
            return value == Constants.tooManyRequestsStatusCode
        }
        return retryCodes
    }()
    var flushLimit: Int
    
    init(flushLimit: Int) {
        self.flushLimit = flushLimit
        eventsQueue = DispatchQueue(label: "com.ometria.eventQueue", qos: .utility)
    }
    
    func processEvent(_ event: OmetriaEvent) {
        eventsQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            Logger.info(message: "Process Event \(event)", category: .events)
            self.saveEvent(event)
            self.flushEventsIfNeeded()
        }
    }
    
    private func flushEventsIfNeeded() {
        eventsQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            let events = self.retrieveFlushableEvents()
            Logger.verbose(message: "Flushable events: \(events.count)", category: .events)
            
            if events.count >= self.flushLimit {
                guard self.canPerformNetworkCall() else {
                    Logger.debug(message: "Attempted to flush events but not enough time has passed since the last flush.", category: .network)
                    return
                }
                
                self.flushEvents()
            }
        }
    }
    
    func flushEvents() {
        eventsQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            let events = self.retrieveFlushableEvents()
            
            guard events.count != 0 else {
                return
            }
            
            let batchedEvents = self.batchEvents(events: events)
            
            for key in batchedEvents.keys {
                let batch = batchedEvents[key]!
                let flushSizedChunks = batch.chunked(into: Constants.flushMaxBatchSize)
                for chunk in flushSizedChunks {
                    self.flushEvents(events: chunk)
                }
            }
        }
    }
    
    private func flushEvents(events: [OmetriaEvent]) {
        Logger.debug(message: "Begin flushing \(events.count) events.", category: .events)
        events.forEach({$0.isBeingFlushed = true})
        
        EventsAPI.flushEvents(events) { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.eventsQueue.async {
                
                switch result {
                case .success(_):
                    Logger.debug(message: "Successfully flushed \(events.count) events.", category: .events)
                    self.removeEvents(events)
                    
                case .failure(let error):
                    Logger.debug(message: "Failed to flush \(events.count) events.", category: .events)
                    
                    if case OmetriaError.apiError(let apiError) = error,
                        self.dropStatusCodes.contains(apiError.status) {
                        Logger.debug(message: "Events will be discarded because server responded with status \(apiError.status).", category: .events)
                        self.removeEvents(events)
                    
                    } else {
                        Logger.debug(message: "Events will be saved for retry.", category: .events)
                        
                        events.forEach({$0.isBeingFlushed = false})
                        self.saveMemoryCachedEvents()
                    }
                }
            }
        }
        
        OmetriaDefaults.networkTimedOutUntilDate = Date(timeIntervalSinceNow: Constants.networkCallTimeoutSeconds)
    }
    
    // MARK: - Cache accessibility
    
    func clearEvents() {
        eventsQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            Logger.debug(message: "Clear all Events from local cache.", category: .events)
            self.trackedEvents.removeAll()
            JSONCache.trackedEvents.saveToFile(nil, async: false)
        }
        
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
        JSONCache.trackedEvents.saveToFile(events, async: false)
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
    
    // MARK: - Network Validation
    
    private func canPerformNetworkCall() -> Bool {
        return Date() > OmetriaDefaults.networkTimedOutUntilDate
    }
}
