//
//  NotificationService.swift
//  OmetriaSampleNotificationService
//
//  Created by Catalin Demian on 30.08.2023.
//  Copyright © 2023 Ometria. All rights reserved.
//

import UserNotifications
import Ometria

class NotificationService: OmetriaNotificationServiceExtension {
    override func instantiateOmetria() -> Ometria? {
        return Ometria.initializeForExtension(appGroupIdentifier: "group.com.tapptitude.ometria.Sample")
    }
}
