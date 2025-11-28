//
//  GNForegroundPresentationPolicy.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//

import UserNotifications

// MARK: - Foreground Policy

public struct GNForegroundPresentationPolicy: Sendable {
    public var showAlert: Bool
    public var playSound: Bool
    public var setBadge: Bool

    @MainActor public static let quiet = GNForegroundPresentationPolicy(
        showAlert: false, playSound: false, setBadge: false
    )
    @MainActor public static let subtleBadge = GNForegroundPresentationPolicy(
        showAlert: false, playSound: false, setBadge: true
    )
    @MainActor public static let banner = GNForegroundPresentationPolicy(
        showAlert: true, playSound: true, setBadge: false
    )
}

public protocol GNForegroundNotificationHandler: AnyObject {
    func presentationPolicy(for notification: UNNotification) -> GNForegroundPresentationPolicy
}

// MARK: - Notify Facade

public enum Notify {
    @MainActor private static var _client: GNLocalNotificationCenter = UNLocalNotificationCenterClient()

    @MainActor public static var client: GNLocalNotificationCenter {
        get { _client }
        set { _client = newValue }
    }

    @MainActor public static func configure(client: GNLocalNotificationCenter = UNLocalNotificationCenterClient()) {
        self._client = client
    }

    @MainActor @discardableResult
    public static func requestAuthorization(
        options: UNAuthorizationOptions = [.alert, .sound, .badge]
    ) async throws -> Bool {
        try await client.requestAuthorization(options: options)
    }

    /// Schedules a simple notification.
    @MainActor public static func schedule(
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

    @MainActor public static func registerCategories(_ categories: [GNNotificationCategoryDescriptor]) async {
        await client.registerCategories(categories)
    }

    @MainActor public static func schedule(_ request: GNNotificationRequest) async throws {
        try await client.schedule(request)
    }

    @MainActor public static func cancel(withIdentifiers ids: [String]) async {
        await client.cancel(withIdentifiers: ids)
    }

    @MainActor public static func cancelAll() async {
        await client.cancelAll()
    }
}

