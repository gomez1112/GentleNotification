//
//  Notify.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//

import UserNotifications
// MARK: - Notify Facade

@MainActor
public enum Notify {
    private static var _client: GNLocalNotificationCenter = UNLocalNotificationCenterClient()

    public static var client: GNLocalNotificationCenter {
        get { _client }
        set { _client = newValue }
    }

    public static func configure(client: GNLocalNotificationCenter = UNLocalNotificationCenterClient()) {
        self._client = client
    }

    @discardableResult
    public static func requestAuthorization(
        options: UNAuthorizationOptions = [.alert, .sound, .badge]
    ) async throws -> Bool {
        try await client.requestAuthorization(options: options)
    }

    /// Schedules a simple notification.
    public static func schedule(
        title: String,
        body: String,
        in offset: GNTimeOffset,
        threadID: String? = nil,
        interruptionLevel: GNInterruptionLevel = .active
    ) async throws {
        let content = GNNotificationContent(
            title: title,
            body: body,
            threadID: threadID,
            privacyBehavior: .genericPlaceholder("Reminder"),
            interruptionLevel: interruptionLevel
        )

        let request = GNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            schedule: .timeInterval(offset, repeats: false),
            policy: .default
        )

        try await client.schedule(request)
    }

    public static func registerCategories(_ categories: [GNNotificationCategoryDescriptor]) async {
        await client.registerCategories(categories)
    }

    public static func schedule(_ request: GNNotificationRequest) async throws {
        try await client.schedule(request)
    }

    public static func cancel(withIdentifiers ids: [String]) async {
        await client.cancel(withIdentifiers: ids)
    }

    public static func cancelAll() async {
        await client.cancelAll()
    }
}
