import Foundation
import Testing
import os
@testable import OrchardKitLogging

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
