//
//  HTTPNetworkResponse.swift
//  Ometria
//
//  Created by Cata on 8/19/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}

extension Result where T == Void {
    static func success() -> Result {
        return .success(())
    }
}
