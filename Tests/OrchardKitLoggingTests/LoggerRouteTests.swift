import Foundation
import Testing
@testable import OrchardKitLogging

@Test("Logger routes a message to every configured route")
func loggerRoutesMessagesToAllRoutes() throws {
    let firstRoute = SpyRoute()
    let secondRoute = SpyRoute()
    let logger = OrchardKitLogging.Logger(routes: [firstRoute, secondRoute])
    let timestamp = Date(timeIntervalSince1970: 1_707_728_000)

    logger.log(
        .warning,
        "Sync delayed",
        metadata: ["attempt": "1", "screen": "home"],
        fileID: "SyncViewModel.swift",
        function: "refresh()",
        line: 88,
        timestamp: timestamp
    )

    #expect(firstRoute.messages.count == 1)
    #expect(secondRoute.messages.count == 1)

    let message = try #require(firstRoute.messages.first)
    #expect(message.level == .warning)
    #expect(message.message == "Sync delayed")
    #expect(message.metadata == ["attempt": "1", "screen": "home"])
    #expect(message.fileID == "SyncViewModel.swift")
    #expect(message.function == "refresh()")
    #expect(message.line == 88)
    #expect(message.timestamp == timestamp)
}

@Test("Logger supports adding routes at runtime")
func loggerAddsRoutesAfterInitialization() {
    let logger = OrchardKitLogging.Logger()
    let route = SpyRoute()

    logger.addRoute(route)
    logger.log(.info, "Boot complete")

    #expect(route.messages.count == 1)
}

@Test("Logger skips payload creation when all routes are disabled")
func loggerSkipsPayloadCreationWhenRoutesAreDisabled() {
    let disabledRoute = DisabledRoute()
    let logger = OrchardKitLogging.Logger(routes: [disabledRoute])
    var messageBuildCount = 0
    var metadataBuildCount = 0
    var timestampBuildCount = 0

    func buildMessage() -> String {
        messageBuildCount += 1
        return "Expensive message"
    }

    func buildMetadata() -> [String: String] {
        metadataBuildCount += 1
        return ["source": "sync"]
    }

    func buildTimestamp() -> Date {
        timestampBuildCount += 1
        return Date(timeIntervalSince1970: 1_707_728_000)
    }

    logger.log(
        .debug,
        buildMessage(),
        metadata: buildMetadata(),
        fileID: "LazySource.swift",
        function: "render()",
        line: 17,
        timestamp: buildTimestamp()
    )

    #expect(messageBuildCount == 0)
    #expect(metadataBuildCount == 0)
    #expect(timestampBuildCount == 0)
    #expect(disabledRoute.loggedMessages == 0)
}

@Test("Logger supports interleaved route updates and logging")
func loggerSupportsInterleavedRouteUpdates() {
    let primaryRoute = SpyRoute()
    let dynamicRoute = SpyRoute()
    let logger = OrchardKitLogging.Logger(routes: [primaryRoute])
    let iterations = 200

    for index in 0..<iterations {
        if index == 50 {
            logger.addRoute(dynamicRoute)
        }

        logger.log(.info, "event-\(index)")
    }

    #expect(primaryRoute.messages.count == iterations)
    #expect(dynamicRoute.messages.count == 150)
}

@Test("Logger exposes file route path")
func loggerExposesFileRoutePath() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let fileRoute = FileLogRoute(
        fileURL: fileURL,
        maxBytes: 512,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    #expect(logger.logFilePath(for: .file) == fileURL.path)
    #expect(logger.logFileURL(for: .file) == fileURL)
    #expect(logger.logFilePath(for: .osLog) == nil)
    #expect(logger.logFileURL(for: .osLog) == nil)
}

@Test("Logger file lookup skips non file route with same type")
func loggerFileLookupSkipsNonFileRouteWithSameType() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let routeWithoutFileLocation = RouteWithoutFileLocation(routeType: .file)
    let fileRoute = FileLogRoute(
        fileURL: fileURL,
        maxBytes: 512,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(
        routes: [routeWithoutFileLocation, fileRoute]
    )

    #expect(logger.logFilePath(for: .file) == fileURL.path)
    #expect(logger.logFileURL(for: .file) == fileURL)
}

@Test("Logger exposes file route path for custom route type")
func loggerExposesFileRoutePathForCustomRouteType() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-custom-file-route.log")
    let routeType = LogRouteType.custom("upload")
    let fileRoute = FileLogRoute(
        fileURL: fileURL,
        routeType: routeType,
        maxBytes: 512,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    #expect(logger.logFilePath(for: routeType) == fileURL.path)
    #expect(logger.logFileURL(for: routeType) == fileURL)
    #expect(logger.logFilePath(for: .file) == nil)
    #expect(logger.logFileURL(for: .file) == nil)
}

@Test("Logger preserves first file path helpers")
func loggerPreservesFirstFilePathHelpers() throws {
    let fileManager = FileManager.default
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
    )
    defer {
        try? fileManager.removeItem(at: directoryURL)
    }

    let fileURL = directoryURL.appendingPathComponent("orchardkit-file-route.log")
    let fileRoute = FileLogRoute(
        fileURL: fileURL,
        maxBytes: 512,
        fileManager: fileManager
    )
    let logger = OrchardKitLogging.Logger(routes: [fileRoute])

    #expect(logger.firstLogFilePath() == fileURL.path)
    #expect(logger.firstLogFileURL() == fileURL)
}
