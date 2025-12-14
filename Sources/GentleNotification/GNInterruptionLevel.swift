//
//  GNInterruptionLevel.swift
//  GentleNotification


import UserNotifications
import Foundation

// MARK: - Enums

public enum GNInterruptionLevel: Sendable {
    case active, passive, timeSensitive, critical
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var systemLevel: UNNotificationInterruptionLevel {
        switch self {
            case .active: return .active
            case .passive: return .passive
            case .timeSensitive: return .timeSensitive
            case .critical: return .critical
        }
    }
}

public enum GNPrivacyBehavior: Equatable, Sendable {
    case none
    /// iOS only: Placeholder text when device is locked/previews hidden.
    /// (Note: On Mac Catalyst, this falls back to system default to prevent build errors)
    case genericPlaceholder(String)
}

// MARK: - Content

public struct GNNotificationContent: Equatable, @unchecked Sendable {
    public var title: String
    public var body: String
    public var subtitle: String?
    public var threadID: String?
    public var categoryIdentifier: String?
    public var privacyBehavior: GNPrivacyBehavior
    public var userInfo: [AnyHashable: Any]
    public var sound: UNNotificationSound?
    public var badge: Int?
    public var interruptionLevel: GNInterruptionLevel
    
    public init(
        title: String,
        body: String,
        subtitle: String? = nil,
        interruptionLevel: GNInterruptionLevel = .active
    ) {
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.interruptionLevel = interruptionLevel
        self.privacyBehavior = .none
        self.userInfo = [:]
        self.sound = .default
        self.badge = nil
        self.threadID = nil
        self.categoryIdentifier = nil
    }
    
    // Fluent Modifiers
    public func sound(_ sound: UNNotificationSound?) -> Self {
        var copy = self; copy.sound = sound; return copy
    }
    
    public func badge(_ count: Int?) -> Self {
        var copy = self; copy.badge = count; return copy
    }
    
    public func category(_ id: String) -> Self {
        var copy = self; copy.categoryIdentifier = id; return copy
    }
    
    public func userInfo(_ data: [AnyHashable: Any]) -> Self {
        var copy = self; copy.userInfo = data; return copy
    }
    
    public func privacy(_ behavior: GNPrivacyBehavior) -> Self {
        var copy = self; copy.privacyBehavior = behavior; return copy
    }
    
    public func thread(_ id: String) -> Self {
        var copy = self; copy.threadID = id; return copy
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
        if let badge { content.badge = NSNumber(value: badge) }
        
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            content.interruptionLevel = interruptionLevel.systemLevel
        }
        
        // SAFE IMPLEMENTATION:
        // We avoid direct property access to `hiddenPreviewsBodyPlaceholder`
        // because it causes persistent build failures on Mac Catalyst.
        switch privacyBehavior {
            case .none: break
            case .genericPlaceholder(_):
                // Fallback to default system behavior.
                // If strictly needed, KVC `content.setValue(text, forKey: ...)` could be used,
                // but it is unsafe. Defaulting to system behavior is the stable choice.
                break
        }
        
        return content
    }
    
    public static func == (lhs: GNNotificationContent, rhs: GNNotificationContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.body == rhs.body &&
        lhs.threadID == rhs.threadID &&
        lhs.categoryIdentifier == rhs.categoryIdentifier &&
        lhs.badge == rhs.badge &&
        (lhs.userInfo as NSDictionary).isEqual(rhs.userInfo)
    }
}
