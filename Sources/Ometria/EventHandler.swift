
//
//  EventHandler.swift
//  Ometria
//
//  Created by Cata on 8/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

class EventHandler {
    private var eventService: EventServiceProtocol
    private var eventCache: EventCaching
    private var eventsQueue: DispatchQueue
    private var oneByOneEventsQueue: DispatchQueue
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
    private let flushInterval: Int
    private var flushTimer: Timer?
    
    init(
        eventService: EventServiceProtocol,
        eventCache: EventCaching,
        flushLimit: Int,
        flushInterval: Int = 60
    ) {
        self.eventService = eventService
        self.eventCache = eventCache
        self.flushLimit = flushLimit
        self.flushInterval = flushInterval
        
        eventsQueue = DispatchQueue(
            label: "com.ometria.eventQueue",
            qos: .utility
        )
        
        oneByOneEventsQueue = DispatchQueue(
            label: "com.ometria.oneByOneEventsQueue",
            qos: .utility
        )
        
        if flushInterval > 0 {
            startFlushTimer()
        }
        
        prepareForAppLifecycleEvents()
    }
    
    deinit {
        stopFlushTimer()
        NotificationCenter.default.removeObserver(self)
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
                self.flushEvents(isFlushRateLimitEnabled: false)
            }
        }
    }
    
    func flushEvents(
        saveFailedForRetry: Bool = true,
        isFlushRateLimitEnabled: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        if isFlushRateLimitEnabled, Date() <= OmetriaDefaults.networkTimedOutUntilDate {
            completion?()
            return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        eventsQueue.async { [weak self] in
            guard let self = self else {
                dispatchGroup.leave()
                return
            }
            
            let events = self.retrieveFlushableEvents()
            
            guard events.count != 0 else {
                dispatchGroup.leave()
                return
            }
            OmetriaDefaults.networkTimedOutUntilDate = Date(timeIntervalSinceNow: Constants.networkCallTimeoutSeconds)
            let batchedEvents = self.batchEvents(events: events)
            
            for key in batchedEvents.keys {
                let batch = batchedEvents[key]!
                let flushSizedChunks = batch.chunked(into: Constants.flushMaxBatchSize)
                for chunk in flushSizedChunks {
                    dispatchGroup.enter()
                    self.flushEvents(events: chunk, saveFailedForRetry: saveFailedForRetry) { success in
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion?()
        }
    }
    
    
    private func flushOneByOne(
        _ events: [OmetriaEvent],
        saveFailedForRetry: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard !events.isEmpty else {
            completion?()
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        oneByOneEventsQueue.async { [weak self] in
            guard let self = self else { return }
            
            for event in events {
                dispatchGroup.enter()
                self.flushEvents(events: [event], saveFailedForRetry: saveFailedForRetry) { _ in
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion?()
            }
        }
    }
    
    private func flushEvents(
        events: [OmetriaEvent],
        saveFailedForRetry: Bool,
        completion: ((_ success: Bool) -> Void)? = nil
    ) {
        Logger.debug(message: "Begin flushing \(events.count) events.", category: .events)
        events.forEach({$0.isBeingFlushed = true})
        
        eventService.flushEvents(events) { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.eventsQueue.async {
                switch result {
                case .success(_):
                    Logger.debug(message: "Successfully flushed \(events.count) events.", category: .events)
                    self.removeEvents(events)
                    completion?(true)
                    
                case .failure(let error):
                    Logger.debug(message: "Failed to flush \(events.count) events.", category: .events)
                    
                    if case OmetriaError.apiError(let apiError) = error,
                       self.dropStatusCodes.contains(apiError.status) {
                        
                        if events.count == 1 {
                            Logger.debug(message: "Events will be discarded because server responded with status \(apiError.status).", category: .events)
                            self.removeEvents(events)
                        } else {
                            self.flushOneByOne(events) {
                                completion?(true)
                            }
                            return
                        }
                    } else {
                        if saveFailedForRetry {
                            Logger.debug(message: "Events will be saved for retry.", category: .events)
                            
                            events.forEach({$0.isBeingFlushed = false})
                            self.saveMemoryCachedEvents()
                        } else {
                            self.removeEvents(events)
                        }
                    }
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - Cache accessibility
    
    func clearEvents() {
        eventsQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            Logger.debug(message: "Clear all Events from local cache.", category: .events)
            self.trackedEvents.removeAll()
            self.eventCache.saveToFile(nil, async: false)
        }
    }
    
    private func retrieveEvents() -> [OmetriaEvent] {
        if !hasLoadedEvents {
            Logger.verbose(message: "Load Events from local cache", category: .cache)
            
            if let cachedEvents = eventCache.loadFromFile() {
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
        eventCache.saveToFile(events, async: false)
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

extension EventHandler {
    private func startFlushTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            flushTimer?.invalidate()
            flushTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(self.flushInterval),
                repeats: true
            ) { [weak self] _ in
                self?.flushEventsIfAny()
            }
        }
    }
    
    private func stopFlushTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.flushTimer?.invalidate()
            self?.flushTimer = nil
        }
    }
    
    private func flushEventsIfAny() {
        eventsQueue.async { [weak self] in
            guard let self else { return }
            let events = retrieveFlushableEvents()
            
            if events.isEmpty {
                return
            }
            
            Logger.debug(message: "Timer-triggered flush: \(events.count) events", category: .events)
            flushEvents(isFlushRateLimitEnabled: false)
        }
    }
}

extension EventHandler {
    private func prepareForAppLifecycleEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        stopFlushTimer()
    }
    
    @objc private func appWillEnterForeground() {
        if flushInterval > 0 {
            startFlushTimer()
        }
    }
}
