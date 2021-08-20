//
//  Constants.swift
//  Ometria
//
//  Created by Cata on 8/25/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

public struct Constants {
    static let sdkVersion = "1.2.0"
    public static let defaultTriggerLimit = 10
    static let flushMaxBatchSize = 100
    static let networkCallTimeoutSeconds: TimeInterval = 10
    static let tooManyRequestsStatusCode: Int = 429
}
