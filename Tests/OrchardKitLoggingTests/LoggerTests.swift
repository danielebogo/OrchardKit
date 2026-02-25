import Foundation
import Testing
import os
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

@Test(
    "OSLogRoute maps custom levels to OSLog types",
    arguments: [
        (LogLevel.notice, OSLogType.default),
        (LogLevel.info, OSLogType.info),
        (LogLevel.debug, OSLogType.debug),
        (LogLevel.trace, OSLogType.debug),
        (LogLevel.warning, OSLogType.error),
        (LogLevel.error, OSLogType.error),
        (LogLevel.fault, OSLogType.fault),
        (LogLevel.critical, OSLogType.fault)
    ]
)
func osLogRouteMapsLogLevels(
    level: LogLevel,
    expectedType: OSLogType
) throws {
    let writer = RecordingOSLogWriter()
    let route = OSLogRoute(writer: writer)
    let timestamp = Date(timeIntervalSince1970: 1_707_728_000)
    let message = LogMessage(
        level: level,
        message: "Download failed",
        metadata: ["errorCode": "500"],
        fileID: "DownloadService.swift",
        function: "start()",
        line: 34,
        timestamp: timestamp
    )

    route.log(message)

    let entry = try #require(writer.entries.first)
    #expect(entry.level == expectedType)
    #expect(
        entry.message
            == "[\(level.rawValue.uppercased())] Download failed | errorCode=500 (DownloadService.swift:34 start())"
    )
}

@Test(
    "OSLogRoute reflects route enablement from writer",
    arguments: [
        (LogLevel.debug, false),
        (LogLevel.info, false),
        (LogLevel.notice, false),
        (LogLevel.trace, false),
        (LogLevel.warning, true),
        (LogLevel.error, true),
        (LogLevel.fault, false),
        (LogLevel.critical, false)
    ]
)
func osLogRouteUsesWriterEnablement(
    level: LogLevel,
    expectedEnabled: Bool
) {
    let writer = RecordingOSLogWriter { type in
        type == .error
    }
    let route = OSLogRoute(writer: writer)

    #expect(route.isEnabled(for: level) == expectedEnabled)
}

private final class SpyRoute: LogRoute {
    private(set) var messages: [LogMessage] = []

    func log(_ message: LogMessage) {
        messages.append(message)
    }
}

private final class DisabledRoute: LogRoute {
    private(set) var loggedMessages = 0

    func isEnabled(for level: LogLevel) -> Bool {
        false
    }

    func log(_ message: LogMessage) {
        loggedMessages += 1
    }
}

private final class RecordingOSLogWriter: OSLogWriting {
    struct Entry {
        let level: OSLogType
        let message: String
    }

    private let isEnabledHandler: (OSLogType) -> Bool
    private(set) var entries: [Entry] = []

    init(isEnabledHandler: @escaping (OSLogType) -> Bool = { _ in true }) {
        self.isEnabledHandler = isEnabledHandler
    }

    func isEnabled(level: OSLogType) -> Bool {
        isEnabledHandler(level)
    }

    func log(
        level: OSLogType,
        message: String
    ) {
        entries.append(Entry(level: level, message: message))
    }
}
