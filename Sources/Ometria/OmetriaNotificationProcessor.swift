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
public final class OmetriaNotificationProcessor {
    /**
     The primary entry point for processing an Ometria notification.
     
     Call this method from your `NotificationService.didReceive` function.
     It will automatically track the notification-received event and
     process any rich push content (like images) before calling your `contentHandler`.
     
     - Parameter request: The original `UNNotificationRequest` received by the service extension.
     - Parameter ometria: An initialized instance of the Ometria SDK.
     - Parameter contentHandler: The `contentHandler` closure from the `didReceive` method.
     */
    public static func handleNotification(
        _ request: UNNotificationRequest,
        using ometria: Ometria,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let trackingGroup = DispatchGroup()
        trackingGroup.enter()
        trackNotificationReceived(using: request.content.userInfo, ometria: ometria) {
            trackingGroup.leave()
        }
        
        let notificationContent = updatedNotificationContent(from: request)
        
        trackingGroup.notify(queue: .main) {
            contentHandler(notificationContent)
        }
    }
}

// MARK: - Private Helpers
extension OmetriaNotificationProcessor {
    /**
     Tracks the notification received event.
     
     Sends the event straight to Ometria. If it fails or times out, the event is saved
     so the app sends it on the next `appForegrounded`.
     
     - Parameter userInfo: The `userInfo` dictionary from the notification content.
     - Parameter ometria: An initialized instance of the Ometria SDK.
     - Parameter completion: Called once, when the event was sent, saved for later, or skipped.
     */
    private static func trackNotificationReceived(
        using userInfo: [AnyHashable: Any],
        ometria: Ometria,
        completion: @escaping () -> Void
    ) {
        guard OmetriaDefaults.isTrackingActivityEnabled,
              let notificationBody = NotificationHandler().parseNotificationContent(userInfo) else {
            completion()
            return
        }
        storeSendId(of: notificationBody)
        
        let event = OmetriaEvent(
            eventType: .notificationReceived,
            data: [Constants.EventKeys.context: notificationBody.context]
        )
        let once = OnceFlag()
        
        let task = ometria.sendEventDirectly(event) { shouldRetry in
            guard once.set() else {
                // Timed out: the task was cancelled and the event is already saved.
                return
            }
            if shouldRetry {
                ExtensionPendingEvents.save(event)
            }
            completion()
        }

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + Constants.extensionSendTimeout) {
            guard once.set() else {
                return
            }
            Logger.debug(message: "Sending event \(event.eventId) timed out.", category: .events)
            task?.cancel()
            ExtensionPendingEvents.save(event)
            completion()
        }
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
    
    /// Stores the `send_id` so the app doesn't track this notification again
    /// (on `willPresent` or when processing delivered notifications).
    private static func storeSendId(of notificationBody: OmetriaNotificationBody) {
        guard let sendId = notificationBody.sendId else {
            return
        }
        var ids = OmetriaDefaults.receivedNotificationIds
        ids[sendId] = Date()
        OmetriaDefaults.receivedNotificationIds = ids
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

/// Lets only the first caller through (the send result or the timeout).
private final class OnceFlag {
    private let lock = NSLock()
    private var isSet = false
    
    func set() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isSet else {
            return false
        }
        isSet = true
        return true
    }
}
