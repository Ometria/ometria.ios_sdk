//
//  OmetriaNotificationServiceExtension.swift
//  Ometria
//
//  Created by Cata on 8/27/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import UserNotifications

open class OmetriaNotificationServiceExtension: UNNotificationServiceExtension {
    /// override this function in subclass
    open func instantiateOmetria() -> Ometria? {
        return nil
    }

    override open func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        guard let ometria = instantiateOmetria() else {
            contentHandler(request.content)
            return
        }
        OmetriaNotificationProcessor.handleNotification(
            request,
            using: ometria
        ) { content in
            contentHandler(content)
        }
    }
}
