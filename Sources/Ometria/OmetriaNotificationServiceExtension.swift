//
//  OmetriaNotificationServiceExtension.swift
//  Ometria
//
//  Created by Cata on 8/27/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UserNotifications

open class OmetriaNotificationServiceExtension: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    open func instantiateOmetria() {
        fatalError("This function needs to be overriden")
    }

    override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        instantiateOmetria()
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let notificationBody = NotificationHandler().parseNotificationContent(request.content) else {
            if let bestAttemptContent = bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
            return
        }
        
        Ometria.sharedInstance().trackNotificationReceivedEvent(context: notificationBody.context)
        Ometria.sharedInstance().flush()
        
        func failEarly() {
            contentHandler(request.content)
        }
        
        if let bestAttemptContent = bestAttemptContent {
            
            guard
                let imageURLString = notificationBody.imageURL,
                let imageURL = URL(string: imageURLString),
                let data = NSData(contentsOf: imageURL) else
            {
                    failEarly()
                    return
            }
            
            guard let imageAttachment = create(imageFileIdentifier: imageURLString.components(separatedBy: "/").last!, data: data, options: nil) else {
                failEarly()
                return
            }
            
            bestAttemptContent.attachments.append(imageAttachment)
            contentHandler(bestAttemptContent)
        }
    }
    
    override open func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func create(imageFileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = tmpSubFolderURL?.appendingPathComponent(imageFileIdentifier)
            try data.write(to: fileURL!)
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL!, options: options)
            
            return imageAttachment
        } catch let error {
            print("error \(error)")
        }
        return nil
    }
    
}

