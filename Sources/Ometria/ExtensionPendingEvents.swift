//
//  ExtensionPendingEvents.swift
//  Ometria
//

import Foundation

/// Events the Notification Service Extension couldn't send.
/// One UserDefaults key per event in the App Group suite, so the NSE (adds keys)
/// and the app (reads + removes keys) never modify the same value.
/// The app imports them on `appForegrounded`.
enum ExtensionPendingEvents {
    private static let keyPrefix = "com.ometria.extension_pending_event."

    private static var defaults: UserDefaults {
        OmetriaDefaults.suite
    }

    /// NSE: saves an event that couldn't be sent.
    static func save(_ event: OmetriaEvent) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(event) else {
            return
        }
        defaults.set(data, forKey: keyPrefix + event.eventId)
        Logger.debug(message: "Saved extension event \(event.eventId) for the app to send.", category: .events)
    }

    /// App: returns every pending event and removes it.
    static func takeAll() -> [OmetriaEvent] {
        let defaults = self.defaults
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return defaults.dictionaryRepresentation()
            .filter { $0.key.hasPrefix(keyPrefix) }
            .compactMap { key, value in
                defer { defaults.removeObject(forKey: key) }
                guard let data = value as? Data else {
                    return nil
                }
                return try? decoder.decode(OmetriaEvent.self, from: data)
            }
    }
}
