//
//  GNNotificationActionDescriptor.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//


import UserNotifications

public struct GNNotificationActionDescriptor: Equatable, Sendable {
    public enum Style: Sendable {
        case normal
        case destructive
    }
    
    public var identifier: String
    public var title: String
    public var style: Style
    public var options: UNNotificationActionOptions
    public var symbolName: String?
    
    public init(
        identifier: String,
        title: String,
        style: Style = .normal,
        options: UNNotificationActionOptions = [],
        symbolName: String? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.style = style
        self.options = options
        self.symbolName = symbolName
    }
    
    func makeUNAction() -> UNNotificationAction {
        let mappedOptions: UNNotificationActionOptions
        switch style {
            case .normal: mappedOptions = options
            case .destructive: mappedOptions = options.union(.destructive)
        }
        
        return UNNotificationAction(identifier: identifier, title: title, options: mappedOptions)
    }
}

public struct GNNotificationCategoryDescriptor: Equatable, Sendable {
    public var identifier: String
    public var actions: [GNNotificationActionDescriptor]
    public var intentIdentifiers: [String]
    public var options: UNNotificationCategoryOptions
    
    public init(
        identifier: String,
        actions: [GNNotificationActionDescriptor],
        intentIdentifiers: [String] = [],
        options: UNNotificationCategoryOptions = []
    ) {
        self.identifier = identifier
        self.actions = Array(actions.prefix(4))
        self.intentIdentifiers = intentIdentifiers
        self.options = options
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
