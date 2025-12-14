//
//  Notify.swift
//  GentleNotification
//
//  Created by Gerard Gomez on 11/27/25.
//


import UserNotifications

@MainActor
public enum Notify {
    private static var _client: GNLocalNotificationCenter = UNLocalNotificationCenterClient()
    
    public static var client: GNLocalNotificationCenter {
        get { _client }
        set { _client = newValue }
    }
    
    public static func configure(client: GNLocalNotificationCenter) {
        self._client = client
    }
    
    @discardableResult
    public static func requestAuthorization(
        options: UNAuthorizationOptions = [.alert, .sound, .badge]
    ) async throws -> Bool {
        try await client.requestAuthorization(options: options)
    }
    
    public static func permissionStatus() async -> GNPermissionStatus {
        await client.authorizationStatus()
    }
    
    @discardableResult
    public static func schedule(
        title: String,
        body: String,
        in offset: GNTimeOffset = .seconds(1),
        threadID: String? = nil
    ) async throws -> String {
        var content = GNNotificationContent(title: title, body: body)
        if let threadID { content.threadID = threadID }
        
        let request = GNNotificationRequest(
            content: content,
            schedule: .timeInterval(offset, repeats: false)
        )
        try await client.schedule(request)
        return request.identifier
    }
    
    @discardableResult
    public static func schedule(_ request: GNNotificationRequest) async throws -> String {
        try await client.schedule(request)
        return request.identifier
    }
    
    public static func registerCategories(_ categories: [GNCategory]) async {
        await client.registerCategories(categories)
    }
    
    public static func registerCategories(_ categories: GNCategory...) async {
        await client.registerCategories(categories)
    }
    
    public static func cancel(ids: [String]) async {
        await client.cancel(withIdentifiers: ids)
    }
    
    public static func cancel(id: String) async {
        await client.cancel(withIdentifiers: [id])
    }
    
    public static func cancelAll() async {
        await client.cancelAll()
    }
}
