//
//  EventCache+Mock.swift
//  OmetriaSampleTests
//
//  Created by Catalin Demian on 18.04.2023.
//  Copyright © 2023 Ometria. All rights reserved.
//

import Foundation
@testable import Ometria
@testable import OmetriaSample

class MockInMemoryEventCache: EventCaching {
    var events: [OmetriaEvent]?
    let saveHandler: () -> Void
    
    init(saveHandler: @escaping () -> Void) {
        self.saveHandler = saveHandler
    }
    
    func saveToFile(_ events: [OmetriaEvent]?, async: Bool) {
        self.events = events
        DispatchQueue.main.async { [weak self] in
            self?.saveHandler()
        }
    }
    
    func loadFromFile() -> [OmetriaEvent]? {
        return events
    }
}
