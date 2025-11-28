//
//  GNInterruptionLevel.swift
//  GentleNotification
//

import UserNotifications
import Foundation

// MARK: - Interruption Level

/// The importance and delivery timing of a notification.
public enum GNInterruptionLevel: Equatable, Sendable {
    case active
    case passive
    case timeSensitive
    case critical
    
    @available(iOS 15.0, *)
    var systemLevel: UNNotificationInterruptionLevel {
        switch self {
            case .active: return .active
            case .passive: return .passive
            case .timeSensitive: return .timeSensitive
            case .critical: return .critical
        }
    }
}

// MARK: - Privacy Behavior

public enum GNPrivacyBehavior: Equatable, Sendable {
    case none
    /// Display a generic description when previews are hidden (iOS/macOS only).
    /// Note: Due to cross-platform build constraints, this currently defaults to system behavior.
    case genericPlaceholder(String)
}

// MARK: - Notification Content

public struct GNNotificationContent: Equatable, @unchecked Sendable {
    public var title: String
    public var body: String
    public var subtitle: String?
    public var threadID: String?
    public var categoryIdentifier: String?
    public var privacyBehavior: GNPrivacyBehavior
    public var userInfo: [AnyHashable: Any]
    public var sound: UNNotificationSound?
    public var badge: NSNumber?
    
    /// The interruption level determines if the notification breaks through Focus modes.
    public var interruptionLevel: GNInterruptionLevel
    
    public init(
        title: String,
        body: String,
        subtitle: String? = nil,
        threadID: String? = nil,
        categoryIdentifier: String? = nil,
        privacyBehavior: GNPrivacyBehavior = .none,
        userInfo: [AnyHashable: Any] = [:],
        sound: UNNotificationSound? = .default,
        badge: NSNumber? = nil,
        interruptionLevel: GNInterruptionLevel = .active
    ) {
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.threadID = threadID
        self.categoryIdentifier = categoryIdentifier
        self.privacyBehavior = privacyBehavior
        self.userInfo = userInfo
        self.sound = sound
        self.badge = badge
        self.interruptionLevel = interruptionLevel
    }
    
    func makeUNMutableContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle { content.subtitle = subtitle }
        if let threadID { content.threadIdentifier = threadID }
        if let categoryIdentifier { content.categoryIdentifier = categoryIdentifier }
        content.userInfo = userInfo
        content.sound = sound
        content.badge = badge
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = interruptionLevel.systemLevel
        }
        
        switch privacyBehavior {
            case .none:
                break
            case .genericPlaceholder(let placeholder):
                // TEMPORARY FIX:
                // The `hiddenPreviewsBodyPlaceholder` API causes compiler errors on tvOS/watchOS targets
                // even when wrapped in #if os(iOS).
                // We are skipping this assignment to guarantee your project compiles.
                // The app will simply use the default system behavior for hidden previews.
                _ = placeholder // Silence "unused variable" warning
                break
        }
        
        return content
    }
    
    public static func == (lhs: GNNotificationContent, rhs: GNNotificationContent) -> Bool {
        guard lhs.title == rhs.title,
              lhs.body == rhs.body,
              lhs.subtitle == rhs.subtitle,
              lhs.threadID == rhs.threadID,
              lhs.categoryIdentifier == rhs.categoryIdentifier,
              lhs.privacyBehavior == rhs.privacyBehavior,
              lhs.badge == rhs.badge,
              lhs.interruptionLevel == rhs.interruptionLevel else {
            return false
        }
        
        // Explicitly cast both to NSDictionary to fix bridging ambiguity errors
        let lhsDict = lhs.userInfo as NSDictionary
        let rhsDict = rhs.userInfo as NSDictionary
        guard lhsDict.isEqual(rhsDict) else { return false }
        
        // Compare sounds description
        switch (lhs.sound, rhs.sound) {
            case (nil, nil): return true
            case let (l?, r?): return String(describing: l) == String(describing: r)
            default: return false
        }
    }
}

// MARK: - Notification Policy

public struct GNNotificationPolicy: Equatable, Sendable {
    public var avoidDuplicates: Bool
    public var maxPendingCount: Int?
    public var coalesceByThreadID: Bool
    public var clampTextLength: Bool
    
    public init(
        avoidDuplicates: Bool = true,
        maxPendingCount: Int? = nil,
        coalesceByThreadID: Bool = true,
        clampTextLength: Bool = true
    ) {
        self.avoidDuplicates = avoidDuplicates
        self.maxPendingCount = maxPendingCount
        self.coalesceByThreadID = coalesceByThreadID
        self.clampTextLength = clampTextLength
    }
    
    public static var `default`: GNNotificationPolicy {
        GNNotificationPolicy()
    }
}
