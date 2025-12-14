//
//  GNNotificationError.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//

@preconcurrency import UserNotifications

public enum GNNotificationError: Error, Equatable {
    case maxPendingCountReached
    case duplicateIdentifier
}

public protocol GNLocalNotificationCenter: Sendable {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func authorizationStatus() async -> GNPermissionStatus
    func registerCategories(_ categories: [GNCategory]) async
    func schedule(_ request: GNNotificationRequest) async throws
    func cancel(withIdentifiers identifiers: [String]) async
    func cancelAll() async
}

public final class UNLocalNotificationCenterClient: GNLocalNotificationCenter, Sendable {
    private let center = UNUserNotificationCenter.current()
    
    public init() {}
    
    public func authorizationStatus() async -> GNPermissionStatus {
        let settings = await center.notificationSettings()
        return GNPermissionStatus(settings.authorizationStatus)
    }
    
    public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }
    
    public func registerCategories(_ categories: [GNCategory]) async {
        let existing = await center.notificationCategories()
        let newCategories = categories.map { $0.makeUNCategory() }
        let combined = Set(existing).union(newCategories)
        center.setNotificationCategories(combined)
    }
    
    public func schedule(_ request: GNNotificationRequest) async throws {
        try await center.add(request.makeUNRequest())
    }
    
    public func cancel(withIdentifiers identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    public func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
}
