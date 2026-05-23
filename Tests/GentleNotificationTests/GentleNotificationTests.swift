import Testing
@testable import GentleNotification
import UserNotifications

@MainActor
final class MockNotificationCenter: GNLocalNotificationCenter {
    var scheduledRequests: [GNNotificationRequest] = []
    var pendingIdentifiersStorage: [String] = []
    var deliveredIdentifiersStorage: [String] = []
    var cancelledDeliveredIdentifiers: [String] = []
    var removedAllDelivered = false

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
    func authorizationStatus() async -> GNPermissionStatus { .authorized }
    func registerCategories(_ categories: [GNCategory]) async {}

    func schedule(_ request: GNNotificationRequest) async throws {
        scheduledRequests.append(request)
        pendingIdentifiersStorage.append(request.identifier)
    }

    func pendingRequestIdentifiers() async -> [String] { pendingIdentifiersStorage }
    func cancel(withIdentifiers identifiers: [String]) async {}
    func cancelAll() async {}

    func deliveredIdentifiers() async -> [String] { deliveredIdentifiersStorage }

    func cancelDelivered(withIdentifiers identifiers: [String]) async {
        cancelledDeliveredIdentifiers = identifiers
    }

    func cancelAllDelivered() async {
        removedAllDelivered = true
    }
}

@Test func contentEqualityIncludesSubtitleAndInterruptionLevel() {
    let base = GNNotificationContent(
        title: "Status",
        body: "Body",
        subtitle: "Original",
        interruptionLevel: .active
    )

    let changedSubtitle = GNNotificationContent(
        title: "Status",
        body: "Body",
        subtitle: "Changed",
        interruptionLevel: .active
    )

    let changedInterruption = GNNotificationContent(
        title: "Status",
        body: "Body",
        subtitle: "Original",
        interruptionLevel: .critical
    )

    #expect(base != changedSubtitle)
    #expect(base != changedInterruption)
}

@Test @MainActor
func deliveredNotificationManagementUsesClient() async throws {
    let mock = MockNotificationCenter()
    mock.deliveredIdentifiersStorage = ["done-1", "done-2"]
    Notify.configure(client: mock)

    let delivered = await Notify.deliveredIdentifiers()

    #expect(delivered == ["done-1", "done-2"])

    await Notify.cancelDelivered(id: "done-1")
    #expect(mock.cancelledDeliveredIdentifiers == ["done-1"])

    await Notify.cancelAllDelivered()
    #expect(mock.removedAllDelivered)
}
