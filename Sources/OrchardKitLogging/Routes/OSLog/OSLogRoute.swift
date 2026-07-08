#if canImport(os)
import os
#else
#error("OSLogRoute requires os logging APIs")
#endif

typealias SystemLogger = os.Logger
typealias SystemOSLog = os.OSLog
typealias SystemLogType = os.OSLogType

protocol OSLogWriting {
    func isEnabled(level: SystemLogType) -> Bool
    func log(
        level: SystemLogType,
        message: String
    )
}

/// A route that forwards log messages to Apple unified logging.
public struct OSLogRoute: LogRoute {
    private let writer: any OSLogWriting
    private let verbosity: LogVerbosity

    /// The route identity used for logger lookups.
    public var routeType: LogRouteType {
        .osLog
    }

    /// Creates a route backed by Apple unified logging.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem passed to `OSLog`.
    ///   - category: The category passed to `OSLog`.
    ///   - verbosity: The maximum verbosity this route accepts.
    public init(
        subsystem: String,
        category: String,
        verbosity: LogVerbosity = .default
    ) {
        self.verbosity = verbosity
        self.writer = DefaultOSLogWriter(
            subsystem: subsystem,
            category: category
        )
    }

    init(
        writer: any OSLogWriting,
        verbosity: LogVerbosity = .default
    ) {
        self.verbosity = verbosity
        self.writer = writer
    }

    /// Returns whether Apple unified logging is enabled for the level and this route accepts the requested verbosity.
    ///
    /// - Parameters:
    ///   - level: The severity of the candidate message.
    ///   - verbosity: The verbosity requested by the log call.
    public func isEnabled(
        for level: LogLevel
    ) -> Bool {
        writer.isEnabled(level: level.osLogType)
    }

    public func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        self.verbosity.includes(verbosity)
            && isEnabled(for: level)
    }

    /// Writes a message to Apple unified logging.
    public func log(_ message: LogMessage) {
        writer.log(
            level: message.level.osLogType,
            message: message.renderedMessage
        )
    }
}

private struct DefaultOSLogWriter: OSLogWriting {
    private let logHandle: SystemOSLog
    private let logger: SystemLogger

    init(
        subsystem: String,
        category: String
    ) {
        let handle = SystemOSLog(
            subsystem: subsystem,
            category: category
        )
        self.logHandle = handle
        self.logger = SystemLogger(handle)
    }

    func isEnabled(level: SystemLogType) -> Bool {
        logHandle.isEnabled(type: level)
    }

    func log(
        level: SystemLogType,
        message: String
    ) {
        logger.log(
            level: level,
            "\(message, privacy: .public)"
        )
    }
}

private extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .notice:
            return .default
        case .info:
            return .info
        case .debug:
            return .debug
        case .trace:
            return .debug
        case .warning, .error:
            return .error
        case .fault, .critical:
            return .fault
        }
    }
}
