import UserNotifications
import Foundation

/**
 A helper class with static methods to process Ometria push notifications.
 
 This class follows a composition pattern, allowing developers to call Ometria's
 notification logic from within their own `UNNotificationServiceExtension`
 without needing to subclass.
 
 This approach ensures compatibility with other third-party SDKs
 (like Firebase, etc.) that also need to process notifications.
 */
internal final class OmetriaNotificationProcessor {
    /**
     The primary entry point for processing an Ometria notification.
     
     Call this method from your `NotificationService.didReceive` function.
     It will automatically track the notification-received event and
     process any rich push content (like images) before calling your `contentHandler`.
     
     - Parameter request: The original `UNNotificationRequest` received by the service extension.
     - Parameter ometria: An initialized instance of the Ometria SDK.
     - Parameter contentHandler: The `contentHandler` closure from the `didReceive` method.
     */
    internal static func handleNotification(
        _ request: UNNotificationRequest,
        using ometria: Ometria,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        trackNotificationReceived(using: request.content.userInfo, ometria: ometria)
        
        let notificationContent = updatedNotificationContent(from: request)
        contentHandler(notificationContent)
    }
}

// MARK: - Private Helpers
extension OmetriaNotificationProcessor {
    /**
     Tracks the notification received event.
     
     This method parses the notification payload and sends a tracking event to Ometria.
     
     - Parameter userInfo: The `userInfo` dictionary from the notification content.
     - Parameter ometria: An initialized instance of the Ometria SDK.
     */
    private static func trackNotificationReceived(
        using userInfo: [AnyHashable: Any],
        ometria: Ometria
    ) {
        guard let notificationBody = NotificationHandler().parseNotificationContent(userInfo) else {
            return
        }
        ometria.trackNotificationReceivedEvent(context: notificationBody.context)
        ometria.flush()
    }
    
    /**
     Processes the notification for rich push content (e.g., images).
     
     If an Ometria image URL is found, this method will:
     1. Download the image synchronously.
     2. Save it to a temporary local file.
     3. Create a `UNNotificationAttachment` from the file.
     4. Add the attachment to a mutable copy of the notification content.
     
     - Parameter request: The original `UNNotificationRequest`.
     - Returns: A `UNNotificationContent` object. This will be the
                original, unmodified content if no image is processed,
                or a `UNMutableNotificationContent` with the image
                attachment if successful.
     */
    private static func updatedNotificationContent(
        from request: UNNotificationRequest
    ) -> UNNotificationContent {
        guard let notificationBody = NotificationHandler().parseNotificationContent(request.content.userInfo)
        else {
            return request.content
        }
        
        if let imageURLString = notificationBody.imageURL,
           let imageURL = URL(string: imageURLString),
           let data = try? Data(contentsOf: imageURL),
           let bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        {
            if let imageAttachment = createAttachment(
                imageFileIdentifier: imageURL.lastPathComponent,
                data: data
            ) {
                bestAttemptContent.attachments.append(imageAttachment)
            }
            return bestAttemptContent
        } else {
            return request.content
        }
    }
}

// MARK: - Attachment Helper
extension OmetriaNotificationProcessor {
    /**
     Creates a `UNNotificationAttachment` from image data.
     
     This helper writes the downloaded data to a temporary file in a
     unique subdirectory, then creates a notification attachment
     pointing to that file.
     
     - Parameter imageFileIdentifier: The desired file name for the image (e.g., "image.png").
     - Parameter data: The raw `Data` of the image.
     - Returns: A `UNNotificationAttachment` object, or `nil` if an error occurred.
     */
    private static func createAttachment(
        imageFileIdentifier: String,
        data: Data
    ) -> UNNotificationAttachment? {
        
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        guard let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(tmpSubFolderName, isDirectory: true)
        else {
            return nil
        }
        
        do {
            try fileManager.createDirectory(
                at: tmpSubFolderURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            try data.write(to: fileURL)
            
            let imageAttachment = try UNNotificationAttachment.init(
                identifier: imageFileIdentifier,
                url: fileURL,
                options: nil
            )
            
            return imageAttachment
        } catch let error {
            print("Ometria: Error creating notification attachment: \(error)")
        }
        
        return nil
    }
}
