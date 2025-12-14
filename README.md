# GentleNotification 🔔

A modern, lightweight, and thread-safe wrapper for `UserNotifications` in Swift. 

GentleNotification provides a fluent API for building notifications, strict concurrency safety (Swift 6 ready), and a SwiftUI-like DSL for defining interactive categories and actions.

## Features

- **🚀 Async/Await:** Fully modern API design using Swift Concurrency.
- **✨ Fluent Builder:** Chain modifiers to configure notification content (`.sound`, `.badge`, etc.).
- **🧩 DSL for Actions:** Define categories and actions using a clean result builder syntax.
- **🛡️ Type-Safe:** Enums for time offsets (`.minutes(5)`) and interruption levels.
- **📱 Cross-Platform:** Supports iOS 15+, macOS 12+, watchOS 8+, and tvOS 15+.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "[https://github.com/yourusername/GentleNotification.git](https://github.com/yourusername/GentleNotification.git)", from: "1.0.0")
]
```
# Quick Start

## 1. Request Permission
Always request authorization early in your app's lifecycle.

```swift
import GentleNotification

Task {
    do {
        let granted = try await Notify.requestAuthorization()
        print("Notifications allowed: \(granted)")
    } catch {
        print("Error: \(error)")
    }
}
```
## 2. Schedule a Simple Notification
Schedule a notification with a simple time offset.

```swift
Task {
    try await Notify.schedule(
        title: "Hello World", 
        body: "This is a gentle notification.", 
        in: .seconds(5)
    )
}
```
## Advanced Usage
### Fluent Content Builder

Create rich notification content using a declarative syntax.

```swift
let content = GNNotificationContent(title: "Daily Goal", body: "Check your progress!")
    .sound(.default)
    .badge(1)
    .interruptionLevel(.timeSensitive)
    .thread("daily-goals")
    .userInfo(["id": 123])

let request = GNNotificationRequest(
    identifier: "goal-reminder",
    content: content,
    schedule: .calendar(DateComponents(hour: 9, minute: 0), repeats: true)
)
try await Notify.schedule(request)
```
## Interactive Notifications

### Register actionable categories using the Result Builder DSL.

```swift
let inviteCategory = GNCategory("INVITE_CATEGORY") {
    GNAction("ACCEPT_ACTION", title: "Accept", icon: "checkmark")
    
    GNAction("DECLINE_ACTION", title: "Decline", style: .destructive, icon: "trash")
    
    // Opens the app when tapped
    GNAction("VIEW_ACTION", title: "View Details", style: .foreground)
}

// Register globally
await Notify.registerCategories(inviteCategory)

// Schedule a notification using this category
let content = GNNotificationContent(title: "New Invite", body: "You have a pending invite.")
    .category("INVITE_CATEGORY")
    
try await Notify.schedule(
    GNNotificationRequest(content: content, schedule: .seconds(1))
)
```

## Management

### Cancel pending or delivered notifications easily.

```swift
// Cancel specific IDs
await Notify.cancel(ids: ["goal-reminder"])

// Cancel everything
await Notify.cancelAll()
```
