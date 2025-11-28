//
//  GNPermissionStatus.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//


import UserNotifications

// MARK: - Permission Status

public enum GNPermissionStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

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

// MARK: - Time Offset

public enum GNTimeOffset: Equatable, Sendable {
    case seconds(TimeInterval)
    case minutes(TimeInterval)
    case hours(TimeInterval)

    var timeInterval: TimeInterval {
        switch self {
        case .seconds(let s): return s
        case .minutes(let m): return m * 60
        case .hours(let h):   return h * 3600
        }
    }
}

// MARK: - Schedule

public enum GNNotificationSchedule: Equatable, Sendable {
    case timeInterval(GNTimeOffset, repeats: Bool)
    case calendar(DateComponents, repeats: Bool)
    case exactDate(Date)

    func makeTrigger() -> UNNotificationTrigger {
        switch self {
        case .timeInterval(let offset, let repeats):
            return UNTimeIntervalNotificationTrigger(
                timeInterval: max(offset.timeInterval, 1),
                repeats: repeats
            )
        case .calendar(let comps, let repeats):
            return UNCalendarNotificationTrigger(
                dateMatching: comps,
                repeats: repeats
            )
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
    public var policy: GNNotificationPolicy

    public init(
        identifier: String,
        content: GNNotificationContent,
        schedule: GNNotificationSchedule,
        policy: GNNotificationPolicy
    ) {
        self.identifier = identifier
        self.content = content
        self.schedule = schedule
        self.policy = policy
    }

    public init(
        identifier: String,
        content: GNNotificationContent,
        schedule: GNNotificationSchedule
    ) {
        self.init(
            identifier: identifier,
            content: content,
            schedule: schedule,
            policy: .default
        )
    }

    func makeUNRequest() -> UNNotificationRequest {
        let trigger = schedule.makeTrigger()
        let content = self.content.makeUNMutableContent()
        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
    }
}

