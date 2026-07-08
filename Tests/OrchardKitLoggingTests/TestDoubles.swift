import Foundation
import os
@testable import OrchardKitLogging

final class SpyRoute: LogRoute {
    private(set) var messages: [LogMessage] = []

    /// Accepts every log level.
    func isEnabled(for _: LogLevel) -> Bool {
        true
    }

    func log(_ message: LogMessage) {
        messages.append(message)
    }
}

struct RouteWithoutFileLocation: LogRoute {
    let routeType: LogRouteType

    /// Accepts every log level.
    func isEnabled(for _: LogLevel) -> Bool {
        true
    }

    func log(_ message: LogMessage) {}
}

final class DisabledRoute: LogRoute {
    private(set) var loggedMessages = 0

    /// Rejects every log level before verbosity-specific filtering.
    func isEnabled(for _: LogLevel) -> Bool {
        false
    }

    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        false
    }

    func log(_ message: LogMessage) {
        loggedMessages += 1
    }
}

final class LowOnlyDisabledRoute: LogRoute {
    private(set) var loggedMessages = 0

    /// Accepts every log level before applying low-verbosity filtering.
    func isEnabled(for _: LogLevel) -> Bool {
        true
    }

    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        verbosity == .low
    }

    func log(_ message: LogMessage) {
        loggedMessages += 1
    }
}

/// Records messages while disabling one configured level through the level-only route hook.
final class LevelOnlyFilteringRoute: LogRoute {
    /// The level this route rejects before log payloads are created.
    private let disabledLevel: LogLevel

    /// Messages accepted by this route.
    private(set) var messages: [LogMessage] = []

    /// Creates a route that rejects the supplied level.
    ///
    /// - Parameter disabledLevel: The log level that should not be routed.
    init(disabledLevel: LogLevel) {
        self.disabledLevel = disabledLevel
    }

    /// Returns whether this route accepts a log level.
    ///
    /// - Parameter level: The level being evaluated by the logger.
    /// - Returns: `false` when `level` matches the configured disabled level.
    func isEnabled(for level: LogLevel) -> Bool {
        level != disabledLevel
    }

    /// Stores an accepted log message for assertions.
    ///
    /// - Parameter message: The routed log message.
    func log(_ message: LogMessage) {
        messages.append(message)
    }
}

final class VerbositySpyRoute: LogRoute {
    private let routeVerbosity: LogVerbosity

    private(set) var messages: [LogMessage] = []

    /// Accepts every log level before applying verbosity filtering.
    func isEnabled(for _: LogLevel) -> Bool {
        true
    }

    init(verbosity: LogVerbosity) {
        self.routeVerbosity = verbosity
    }

    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        routeVerbosity.includes(verbosity)
    }

    func log(_ message: LogMessage) {
        messages.append(message)
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
