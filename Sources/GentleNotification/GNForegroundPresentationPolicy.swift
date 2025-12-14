//
//  GNForegroundPresentationPolicy.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//

import UserNotifications

public struct GNForegroundPresentationPolicy: Sendable {
    public var showAlert: Bool
    public var playSound: Bool
    public var setBadge: Bool
    
    public init(showAlert: Bool, playSound: Bool, setBadge: Bool) {
        self.showAlert = showAlert
        self.playSound = playSound
        self.setBadge = setBadge
    }
    
    public static var quiet: GNForegroundPresentationPolicy {
        GNForegroundPresentationPolicy(showAlert: false, playSound: false, setBadge: false)
    }
    
    public static var subtleBadge: GNForegroundPresentationPolicy {
        GNForegroundPresentationPolicy(showAlert: false, playSound: false, setBadge: true)
    }
    
    public static var banner: GNForegroundPresentationPolicy {
        GNForegroundPresentationPolicy(showAlert: true, playSound: true, setBadge: false)
    }
}

public protocol GNForegroundNotificationHandler: AnyObject {
    func presentationPolicy(for notification: UNNotification) -> GNForegroundPresentationPolicy
}
