//
//  GNForegroundPresentationPolicy.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//

import UserNotifications

import UserNotifications

// MARK: - Foreground Policy

public struct GNForegroundPresentationPolicy: Sendable {
    public var showAlert: Bool
    public var playSound: Bool
    public var setBadge: Bool
    
    // FIXED: Using computed properties to avoid global state isolation issues.
    // This allows these to be accessed from any actor/thread safely.
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

