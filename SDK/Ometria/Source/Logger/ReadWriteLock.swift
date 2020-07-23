//
//  LogQueue.swift
//  Ometria
//
//  Created by Cata on 7/22/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

class ReadWriteLock {
    let concurentQueue: DispatchQueue

    init(label: String) {
        self.concurentQueue = DispatchQueue(label: label, attributes: .concurrent)
    }

    func read(closure: () -> ()) {
        self.concurentQueue.sync {
            closure()
        }
    }
    func write(closure: () -> ()) {
        self.concurentQueue.sync(flags: .barrier, execute: {
            closure()
        })
    }
}
