//
//  EventService+Mock.swift
//  OmetriaSampleTests
//
//  Created by Catalin Demian on 18.04.2023.
//  Copyright © 2023 Ometria. All rights reserved.
//

import Foundation
@testable import Ometria
@testable import OmetriaSample

extension OmetriaEvent: Hashable {
    public static func == (lhs: OmetriaEvent, rhs: OmetriaEvent) -> Bool {
        return lhs.eventId == rhs.eventId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(eventId)
    }
}

struct MockSuccessEventService: EventServiceProtocol {
    func validateEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>) -> ()) {
        completion(.success(""))
    }
    
    func flushEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>) -> ()) {
        completion(.success(""))
    }
}

class MockSuccessAndCountEventService: EventServiceProtocol {
    var uniqueFlushedEvents: Set<OmetriaEvent> = []
    
    func validateEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>) -> ()) {
        completion(.success(""))
    }
    
    func flushEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>) -> ()) {
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                uniqueFlushedEvents.formUnion(events)
            }
            completion(.success(""))
        }
    }
}

enum MockEventError: Error {
    case failed
}

struct MockFailureEventService: EventServiceProtocol {
    func validateEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>) -> ()) {
        completion(.failure(MockEventError.failed))
    }
    
    func flushEvents(_ events: [OmetriaEvent], completion: @escaping (Result<Any>) -> ()) {
        completion(.failure(MockEventError.failed))
    }
}

