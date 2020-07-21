//
//  ApplicationUtils.swift
//  Ometria
//
//  Created by Cata on 7/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

extension Ometria {
    
    static func isiOSAppExtension() -> Bool {
        return Bundle.main.bundlePath.hasSuffix(".appex")
    }
    
    static func sharedUIApplication() -> UIApplication? {
        guard let sharedApplication = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication else {
            return nil
        }
        return sharedApplication
    }
}
