//
//  GNNotificationError.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//


@preconcurrency import UserNotifications

/// Errors that can occur when scheduling notifications.
public enum GNNotificationError: Error, Equatable {
    case maxPendingCountReached
    case duplicateIdentifier
}

public protocol GNLocalNotificationCenter: Sendable {
    var rawCenter: UNUserNotificationCenter { get }
    func authorizationStatus() async -> GNPermissionStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func registerCategories(_ categories: [GNNotificationCategoryDescriptor]) async
    
    /// Schedules a notification. Throws `GNNotificationError` if policy is violated.
    func schedule(_ request: GNNotificationRequest) async throws
    
    func cancel(withIdentifiers identifiers: [String]) async
    func cancelAll() async
}

public final class UNLocalNotificationCenterClient: GNLocalNotificationCenter, Sendable {
    public let rawCenter: UNUserNotificationCenter
    
    public init(center: UNUserNotificationCenter = .current()) {
        self.rawCenter = center
    }
    
    public func authorizationStatus() async -> GNPermissionStatus {
        let settings = await rawCenter.notificationSettings()
        return GNPermissionStatus(settings.authorizationStatus)
    }
    
    public func requestAuthorization(
        options: UNAuthorizationOptions = [.alert, .sound, .badge]
    ) async throws -> Bool {
        try await rawCenter.requestAuthorization(options: options)
    }
    
    public func registerCategories(_ categories: [GNNotificationCategoryDescriptor]) async {
        let existing = await rawCenter.notificationCategories()
        let newCategories = categories.map { $0.makeUNCategory() }
        let combined = Set(existing).union(newCategories)
        rawCenter.setNotificationCategories(combined)
    }
    
    public func schedule(_ request: GNNotificationRequest) async throws {
        let policy = request.policy
        let pending = await rawCenter.pendingNotificationRequests()
        
        // 1. Max Count Policy
        if let max = policy.maxPendingCount, pending.count >= max {
            throw GNNotificationError.maxPendingCountReached
        }
        
        // 2. Duplicate Policy
        if policy.avoidDuplicates {
            let exists = pending.contains { $0.identifier == request.identifier }
            if exists { throw GNNotificationError.duplicateIdentifier }
        }
        
        // 3. Coalescing Policy
        if policy.coalesceByThreadID, let threadID = request.content.threadID {
            // Remove Pending
            let pendingToRemove = pending.filter {
                $0.content.threadIdentifier == threadID &&
                $0.identifier != request.identifier
            }
            if !pendingToRemove.isEmpty {
                rawCenter.removePendingNotificationRequests(withIdentifiers: pendingToRemove.map(\.identifier))
            }
            
            // Remove Delivered
            let delivered = await rawCenter.deliveredNotifications()
            let deliveredToRemove = delivered.filter {
                $0.request.content.threadIdentifier == threadID &&
                $0.request.identifier != request.identifier
            }
            if !deliveredToRemove.isEmpty {
                rawCenter.removeDeliveredNotifications(withIdentifiers: deliveredToRemove.map(\.request.identifier))
            }
        }
        
        var adjustedRequest = request
        
        // 4. Text Clamping Policy
        if policy.clampTextLength {
            adjustedRequest.content.title = String(adjustedRequest.content.title.prefix(60))
            adjustedRequest.content.body = String(adjustedRequest.content.body.prefix(200))
        }
        
        let unRequest = adjustedRequest.makeUNRequest()
        try await rawCenter.add(unRequest)
    }
    
    public func cancel(withIdentifiers identifiers: [String]) async {
        rawCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    public func cancelAll() async {
        rawCenter.removeAllPendingNotificationRequests()
    }
}
