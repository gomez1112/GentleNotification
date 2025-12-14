//
//  GNPermissionStatus.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.

import UserNotifications

// MARK: - Status
public enum GNPermissionStatus: Equatable, Sendable {
    case notDetermined, denied, authorized, provisional, ephemeral
    
    init(_ status: UNAuthorizationStatus) {
        switch status {
            case .notDetermined: self = .notDetermined
            case .denied:        self = .denied
            case .authorized:    self = .authorized
            case .provisional:   self = .provisional
            case .ephemeral:     self = .ephemeral
            @unknown default:    self = .notDetermined
        }
    }
}

// MARK: - Time & Schedule

public enum GNTimeOffset: Equatable, Sendable {
    case seconds(TimeInterval)
    case minutes(TimeInterval)
    case hours(TimeInterval)
    
    var timeInterval: TimeInterval {
        switch self {
            case .seconds(let t): return t
            case .minutes(let t): return t * 60
            case .hours(let t): return t * 3600
        }
    }
}

public enum GNNotificationSchedule: Equatable, Sendable {
    case timeInterval(GNTimeOffset, repeats: Bool)
    case calendar(DateComponents, repeats: Bool)
    case exactDate(Date)
    
    func makeTrigger() -> UNNotificationTrigger {
        switch self {
            case .timeInterval(let offset, let repeats):
                return UNTimeIntervalNotificationTrigger(
                    timeInterval: max(offset.timeInterval, 0.1),
                    repeats: repeats
                )
            case .calendar(let comps, let repeats):
                return UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
            case .exactDate(let date):
                let comps = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: date
                )
                return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        }
    }
}

// MARK: - Request

public struct GNNotificationRequest: Equatable, Sendable {
    public var identifier: String
    public var content: GNNotificationContent
    public var schedule: GNNotificationSchedule
    
    public init(
        identifier: String = UUID().uuidString,
        content: GNNotificationContent,
        schedule: GNNotificationSchedule
    ) {
        self.identifier = identifier
        self.content = content
        self.schedule = schedule
    }
    
    func makeUNRequest() -> UNNotificationRequest {
        UNNotificationRequest(
            identifier: identifier,
            content: content.makeUNMutableContent(),
            trigger: schedule.makeTrigger()
        )
    }
}
