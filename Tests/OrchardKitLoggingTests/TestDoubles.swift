import Foundation
import os
@testable import OrchardKitLogging

final class SpyRoute: LogRoute {
    private(set) var messages: [LogMessage] = []

    func log(_ message: LogMessage) {
        messages.append(message)
    }
}

struct RouteWithoutFileLocation: LogRoute {
    let routeType: LogRouteType

    func log(_ message: LogMessage) {}
}

final class DisabledRoute: LogRoute {
    private(set) var loggedMessages = 0

    func isEnabled(for level: LogLevel) -> Bool {
        false
    }

    func log(_ message: LogMessage) {
        loggedMessages += 1
    }
}

final class RecordingOSLogWriter: OSLogWriting {
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
