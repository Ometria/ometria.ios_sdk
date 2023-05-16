//
//  OmetriaSampleTests.swift
//  OmetriaSampleTests
//
//  Created by Catalin Demian on 18.04.2023.
//  Copyright © 2023 Ometria. All rights reserved.
//

import XCTest
@testable import Ometria

final class OmetriaSampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ometria_cacheEventSuccess() throws {
        //given
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        let cache = MockInMemoryEventCache {
            expectation.fulfill()
        }
        let service = MockSuccessEventService()
        let ometria = Ometria.init(apiToken: "token", config: OmetriaConfig(), eventService: service, eventCache: cache)
        
        //when
        ometria.trackAppInstalledEvent()
        ometria.trackAppLaunchedEvent()
        ometria.trackErrorOccuredEvent(error: .invalidAPIResponse)
        
        
        //then
        wait(for: [expectation], timeout: 0.1)
        XCTAssertTrue(cache.events?.count == 3, "Expected 3 events in cache, but got \(cache.events?.count ?? 0)")
    }
    
    func test_ometria_successfulFlush_removesEventsFromCache() throws {
        //given
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 4 // 3 times for tracking the  events, and 1 time for removing them when successfully flushed
        let cache = MockInMemoryEventCache {
            expectation.fulfill()
        }
        let service = MockSuccessEventService()
        let ometria = Ometria.init(apiToken: "token", config: OmetriaConfig(), eventService: service, eventCache: cache)
        
        //when
        ometria.trackAppInstalledEvent()
        ometria.trackAppLaunchedEvent()
        ometria.trackErrorOccuredEvent(error: .invalidAPIResponse)
        ometria.flush()
        
        //then
        wait(for: [expectation], timeout: 0.1)
        XCTAssertTrue(cache.events?.count == 0, "Expected 0 events in cache, but got \(cache.events?.count ?? 0)")
    }
    
    func test_ometria_sharedInitializer_successfullyPassesCacheAndEventService() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 1 // 3 times for tracking the  events, and 1 time for removing them when successfully flushed
        let cache = MockInMemoryEventCache {
            expectation.fulfill()
        }
        let service = MockSuccessEventService()
        Ometria.initialize(apiToken: "token", eventCache: cache, eventService: service)
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_ometria_sharedInitializer_withSwizzlingEnabled_addsSwizzlers() {
        let cache = MockInMemoryEventCache {
        }
        let eventService = MockSuccessEventService()
        Ometria.initialize(apiToken: "token", eventCache: cache, eventService: eventService, enableSwizzling: true)
        
        XCTAssertTrue(Swizzler.swizzles.count > 0, "Expected a positive, non-null number of swizzles, but got none")
    }
    
    func test_ometria_sharedInitializer_withSwizzlingDisabled_doesntAddSwizzles() {
        let cache = MockInMemoryEventCache {
        }
        let eventService = MockSuccessEventService()
        Ometria.initialize(apiToken: "token", eventCache: cache, eventService: eventService, enableSwizzling: false)
        
        XCTAssertTrue(Swizzler.swizzles.count == 0, "Expected no swizzles")
    }
    
    func test_ometria_reinitializationWithoutSwizzling_removesSwizzles() {
        let cache = MockInMemoryEventCache {
        }
        let eventService = MockSuccessEventService()
        Ometria.initialize(apiToken: "token", eventCache: cache, eventService: eventService, enableSwizzling: true)
        Ometria.initialize(apiToken: "token", eventCache: cache, eventService: eventService, enableSwizzling: false)
        
        XCTAssertTrue(Swizzler.swizzles.count == 0, "Expected no swizzles")
    }
    
    func test_ometria_reinitializationWithSwizzling_resetsSwizzles() {
        let cache = MockInMemoryEventCache {
        }
        let eventService = MockSuccessEventService()
        Ometria.initialize(apiToken: "token", eventCache: cache, eventService: eventService, enableSwizzling: true)
        let swizzleCount = Swizzler.swizzles.count
        Ometria.initialize(apiToken: "token", eventCache: cache, eventService: eventService, enableSwizzling: true)
        
        // we cannot compare number of swizzled methods, as that would ignore the number of methods that were given an implementation at runtime during the first swizzling iteration
        XCTAssertTrue(Swizzler.swizzles.count >= swizzleCount && Swizzler.swizzles.count <= 2 * swizzleCount, "Expected to have at least \(swizzleCount), and less than (\(2 * swizzleCount) swizzled methods")
    }
    
    func test_ometria_reinitialization_successfullyFlushesAllEvents() {
        let eventService1 = MockSuccessAndCountEventService()
        let eventService2 = MockSuccessAndCountEventService()
        let cache1 = MockInMemoryEventCache {
        }
        let cache2 = MockInMemoryEventCache {
        }
        Ometria.initialize(apiToken: "token", eventCache: cache1, eventService: eventService1, enableSwizzling: false)
        for _ in 0..<100 {
            Ometria.sharedInstance().trackProductViewedEvent(productId: UUID().uuidString)
        }
        Ometria.initialize(apiToken: "token", eventCache: cache2, eventService: eventService2, enableSwizzling: false)
        
        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 11)
        XCTAssertTrue(eventService1.uniqueFlushedEvents.count >= 100, "Expected to flush more than 100 events, but got only \(eventService1.uniqueFlushedEvents.count)")
    }
    
    func test_ometria_instanceReset_clearsCache() {
        let eventService = MockFailureEventService()
        let cache1 = EventCache(relativePathComponent: "1")
        let cache2 = EventCache(relativePathComponent: "2")
        Ometria.initialize(apiToken: "test", eventCache: cache1, eventService: eventService)
        for _ in 0..<100 {
            Ometria.sharedInstance().trackProductViewedEvent(productId: UUID().uuidString)
        }
        Ometria.initialize(apiToken: "test2", eventCache: cache2, eventService: eventService)
        
        
        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 0.5)
        let events = cache1.loadFromFile()
        XCTAssertTrue(events == nil || events?.count == 0, "Expected to have 0 items in cache, but found some")
    }
}
