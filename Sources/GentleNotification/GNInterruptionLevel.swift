//
//  GNInterruptionLevel.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//


import UserNotifications

// MARK: - Interruption Level (New)

/// The importance and delivery timing of a notification.
public enum GNInterruptionLevel: Equatable, Sendable {
    /// Presented immediately, lights up screen, plays sound. Default behavior.
    case active
    /// Adds to notification list without lighting up screen or playing sound.
    case passive
    /// Presented immediately, breaks through Focus modes (requires entitlement).
    case timeSensitive
    /// Presented immediately, breaks through mute switch and Focus modes (requires entitlement).
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
            // UNMutableNotificationContent does not expose a hidden previews placeholder API on all OS versions.
            // As a best-effort fallback, set the body to the placeholder when previews may be hidden.
            // Callers can conditionally set this based on their own privacy rules.
            content.body = placeholder
        }

        return content
    }

    public static func == (lhs: GNNotificationContent, rhs: GNNotificationContent) -> Bool {
        // Compare simple equatable properties directly
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

        // Compare userInfo dictionaries by NSDictionary equality
        let lhsUserInfo = lhs.userInfo as NSDictionary
        let rhsUserInfo = rhs.userInfo as NSDictionary
        guard lhsUserInfo.isEqual(to: rhsUserInfo as! [AnyHashable: Any]) else { return false }

        // Compare sounds by their textual description (best-effort)
        switch (lhs.sound, rhs.sound) {
        case (nil, nil):
            break
        case let (l?, r?):
            // UNNotificationSound is not Equatable. Compare debugDescription strings.
            guard String(describing: l) == String(describing: r) else { return false }
        default:
            return false
        }

        return true
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

    public static let `default` = GNNotificationPolicy()
}

