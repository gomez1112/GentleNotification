//
//  GNNotificationActionDescriptor.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//

import UserNotifications

// MARK: - Action

public struct GNAction: Equatable, Sendable {
    public enum Style: Sendable {
        case normal
        case destructive
        case foreground
        case authRequired
        
        var options: UNNotificationActionOptions {
            switch self {
                case .normal: return []
                case .destructive: return .destructive
                case .foreground: return .foreground
                case .authRequired: return .authenticationRequired
            }
        }
    }
    
    public var identifier: String
    public var title: String
    public var style: Style
    public var icon: String? // SF Symbol name
    
    public init(_ identifier: String, title: String, style: Style = .normal, icon: String? = nil) {
        self.identifier = identifier
        self.title = title
        self.style = style
        self.icon = icon
    }
    
    func makeUNAction() -> UNNotificationAction {
        let options = style.options
        
        if let icon, #available(iOS 15.0, macOS 12.0, watchOS 8.0, *) {
            return UNNotificationAction(identifier: identifier, title: title, options: options, icon: .init(systemImageName: icon))
        } else {
            return UNNotificationAction(identifier: identifier, title: title, options: options)
        }
    }
}

// MARK: - Category & Result Builder

public struct GNCategory: Equatable, Sendable {
    public var identifier: String
    public var actions: [GNAction]
    public var intentIdentifiers: [String]
    public var options: UNNotificationCategoryOptions
    
    public init(
        _ identifier: String,
        options: UNNotificationCategoryOptions = [],
        intentIdentifiers: [String] = [],
        @GNActionBuilder actions: () -> [GNAction] = { [] }
    ) {
        self.identifier = identifier
        self.options = options
        self.intentIdentifiers = intentIdentifiers
        self.actions = Array(actions().prefix(4))
    }
    
    func makeUNCategory() -> UNNotificationCategory {
        let unActions = actions.map { $0.makeUNAction() }
        return UNNotificationCategory(
            identifier: identifier,
            actions: unActions,
            intentIdentifiers: intentIdentifiers,
            options: options
        )
    }
}

@resultBuilder
public struct GNActionBuilder {
    public static func buildBlock(_ components: GNAction...) -> [GNAction] {
        components
    }
}
