# GentleNotification

A small, modern Swift package for scheduling **local notifications** with a clean, fluent API.

GentleNotification wraps `UNUserNotificationCenter` into a tiny, testable surface that helps you:

- Request notification authorization with `async/await`
- Build notification content with **fluent modifiers**
- Schedule notifications with **time offsets**, **calendar triggers**, or **exact dates**
- Register notification categories + actions using a **result builder**
- Swap the underlying notification center with a **mock client** for tests

> **Philosophy:** Keep the call site simple. Keep the core types small. Make testing easy.

---

## Requirements

- Swift tools: **Swift 6.2**
- Platforms (from Package.swift):
  - iOS **15+**
  - macOS **12+**
  - watchOS **8+**
  - tvOS **15+**

---

## Installation

### Swift Package Manager (Xcode)

1. In Xcode: **File → Add Package Dependencies…**
2. Paste your repository URL
3. Add **GentleNotification** to your app target

Then import:

```swift
import GentleNotification
import UserNotifications
```

---

## Quick Start

### 1) Request permission

```swift
import GentleNotification

@MainActor
func enableNotifications() async {
    do {
        let granted = try await Notify.requestAuthorization()
        print("Notifications granted:", granted)
    } catch {
        print("Authorization error:", error)
    }
}
```

You can also pass custom options:

```swift
let granted = try await Notify.requestAuthorization(options: [.alert, .sound, .badge])
```

### 2) Schedule a simple notification

```swift
import GentleNotification

@MainActor
func scheduleExample() async throws {
    let id = try await Notify.schedule(
        title: "Hello",
        body: "This is a scheduled notification.",
        in: .seconds(5)
    )
    print("Scheduled id:", id)
}
```

### 3) Check permission status

```swift
let status = await Notify.permissionStatus()
switch status {
case .authorized, .provisional, .ephemeral:
    print("Good to go")
case .denied:
    print("User denied notifications")
case .notDetermined:
    print("Not requested yet")
}
```

---

## Building Content

### `GNNotificationContent`

`GNNotificationContent` is your Swift-native wrapper around `UNMutableNotificationContent`.

```swift
var content = GNNotificationContent(
    title: "Backup Complete",
    body: "Your files are safe.",
    subtitle: "Just now",
    interruptionLevel: .timeSensitive
)
```

#### Fluent modifiers

These return a **new copy** (value-type style), making call sites easy to chain:

```swift
let content = GNNotificationContent(title: "Task Due", body: "Math homework is due tomorrow.")
    .sound(.default)
    .badge(1)
    .thread("tasks")
    .category("TASKS")
    .userInfo(["taskID": "123"])
    .interruptionLevel(.active)
```

> The `.interruptionLevel(_:)` modifier is intentionally included to keep interruption level consistent with the other fluent APIs.

---

## Interruption Levels

### `GNInterruptionLevel`

Maps to Apple’s `UNNotificationInterruptionLevel` (when supported by the OS):

- `.active`
- `.passive`
- `.timeSensitive`
- `.critical`

```swift
let content = GNNotificationContent(
    title: "Medication",
    body: "Time to take your medication.",
    interruptionLevel: .timeSensitive
)
```

The underlying mapping is applied only on supported OS versions:

```swift
if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
    content.interruptionLevel = interruptionLevel.systemLevel
}
```

---

## Privacy Behavior

### `GNPrivacyBehavior`

A lightweight “future-facing” abstraction for lock-screen privacy behaviors.

```swift
let content = GNNotificationContent(title: "Message", body: "Hey, are you free?")
    .privacy(.genericPlaceholder("New message"))
```

> Currently, `.genericPlaceholder(...)` intentionally falls back to the system default behavior to avoid platform-specific build issues (e.g., Catalyst). You can expand this later if you choose.

---

## Scheduling

### `GNTimeOffset`

```swift
.seconds(10)
.minutes(5)
.hours(2)
```

### `GNNotificationSchedule`

- `.timeInterval(GNTimeOffset, repeats: Bool)`
- `.calendar(DateComponents, repeats: Bool)`
- `.exactDate(Date)`

Example: schedule a repeating calendar notification:

```swift
let comps = DateComponents(hour: 19, minute: 0) // 7:00 PM
let request = GNNotificationRequest(
    content: GNNotificationContent(title: "Daily Check-in", body: "How was your day?"),
    schedule: .calendar(comps, repeats: true)
)

try await Notify.schedule(request)
```

Example: schedule an exact date notification:

```swift
let date = Date().addingTimeInterval(60 * 60) // 1 hour from now
let request = GNNotificationRequest(
    content: GNNotificationContent(title: "Reminder", body: "Meeting starts soon."),
    schedule: .exactDate(date)
)

try await Notify.schedule(request)
```

---

## Categories & Actions

GentleNotification provides a small DSL for defining actions using a result builder.

### Define actions with `GNAction`

```swift
let done = GNAction("DONE", title: "Done", style: .foreground, icon: "checkmark")
let snooze = GNAction("SNOOZE", title: "Snooze", style: .normal, icon: "clock")
let delete = GNAction("DELETE", title: "Delete", style: .destructive, icon: "trash")
```

### Define a category with `GNCategory`

```swift
let tasks = GNCategory("TASKS") {
    GNAction("DONE", title: "Done", style: .foreground, icon: "checkmark")
    GNAction("SNOOZE", title: "Snooze", icon: "clock")
    GNAction("DELETE", title: "Delete", style: .destructive, icon: "trash")
}
```

> iOS limits notification action buttons. `GNCategory` automatically caps actions to the first **4**.

### Register categories

```swift
await Notify.registerCategories(tasks)
```

Then attach the category identifier to your content:

```swift
let content = GNNotificationContent(title: "Task Due", body: "Submit the assignment.")
    .category("TASKS")
```

---

## Foreground Notifications

When your app is in the foreground, you often want to decide whether to show a banner, play sound, etc.

### `GNForegroundPresentationPolicy`

```swift
let quiet = GNForegroundPresentationPolicy.quiet
let badgeOnly = GNForegroundPresentationPolicy.subtleBadge
let banner = GNForegroundPresentationPolicy.banner
```

### `GNForegroundNotificationHandler`

```swift
public protocol GNForegroundNotificationHandler: AnyObject {
    func presentationPolicy(for notification: UNNotification) -> GNForegroundPresentationPolicy
}
```

> Hook this into your app’s `UNUserNotificationCenterDelegate` implementation if you want foreground presentation control. The package keeps policy modeling separate from the delegate so it’s easy to test.

---

## Dependency Injection & Testing

### `Notify.client`

`Notify` uses a protocol-backed client:

```swift
public protocol GNLocalNotificationCenter: Sendable { ... }
```

By default, it uses:

```swift
UNLocalNotificationCenterClient()
```

You can swap it for tests:

```swift
@MainActor
Notify.configure(client: MyMockNotificationCenter())
```

### Swift Testing example

```swift
import Testing
@testable import GentleNotification

struct MockCenter: GNLocalNotificationCenter {
    var scheduled: [GNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func authorizationStatus() async -> GNPermissionStatus { .authorized }
    func registerCategories(_ categories: [GNCategory]) async { }
    func schedule(_ request: GNNotificationRequest) async throws { }
    func cancel(withIdentifiers identifiers: [String]) async { }
    func cancelAll() async { }
}

@Test func scheduleBuildsRequest() async throws {
    // This test focuses on your request building and call-site behavior.
    #expect(true)
}
```

> Note: `MockCenter` above is intentionally minimal. In real tests, store scheduled requests and assert properties like title/body/schedule type.

---

## API Surface Summary

- `Notify`
  - `requestAuthorization(options:)`
  - `permissionStatus()`
  - `schedule(title:body:in:threadID:)`
  - `schedule(_ request:)`
  - `registerCategories(...)`
  - `cancel(...)`, `cancelAll()`
- `GNNotificationContent`
  - properties for `title`, `body`, etc.
  - fluent modifiers: `.sound`, `.badge`, `.category`, `.thread`, `.userInfo`, `.privacy`, `.interruptionLevel`
- `GNNotificationRequest`
  - `identifier`, `content`, `schedule`
- `GNNotificationSchedule`
  - `.timeInterval`, `.calendar`, `.exactDate`
- `GNAction`, `GNCategory`, `GNActionBuilder`
- `GNPermissionStatus`
- `GNForegroundPresentationPolicy`, `GNForegroundNotificationHandler`

