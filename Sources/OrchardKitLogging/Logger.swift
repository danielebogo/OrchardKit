import Foundation

/// A destination that receives routed log messages.
public protocol LogRoute {
    var routeType: LogRouteType { get }
    func isEnabled(for level: LogLevel) -> Bool
    func log(_ message: LogMessage)
}

public protocol LogFileLocationProviding {
    var logFileURL: URL { get }
}

public enum LogRouteType: Hashable, Sendable {
    case osLog
    case file
    case custom(String)
}

public extension LogRoute {
    var routeType: LogRouteType {
        .custom(String(describing: type(of: self)))
    }

    func isEnabled(for level: LogLevel) -> Bool {
        true
    }
}

public enum LogLevel: String, CaseIterable, Sendable {
    case notice
    case info
    case debug
    case trace
    case warning
    case error
    case fault
    case critical
}

public struct LogMessage: Equatable, Sendable {
    public let level: LogLevel
    public let message: String
    public let metadata: [String: String]
    public let fileID: String
    public let function: String
    public let line: UInt
    public let timestamp: Date

    public init(
        level: LogLevel,
        message: String,
        metadata: [String: String] = [:],
        fileID: String,
        function: String,
        line: UInt,
        timestamp: Date = Date()
    ) {
        self.level = level
        self.message = message
        self.metadata = metadata
        self.fileID = fileID
        self.function = function
        self.line = line
        self.timestamp = timestamp
    }

    public var renderedMessage: String {
        let metadataDescription = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let metadataSuffix = metadataDescription.isEmpty ? "" : " | \(metadataDescription)"

        return "[\(level.rawValue.uppercased())] \(message)\(metadataSuffix) (\(fileID):\(line) \(function))"
    }
}

public final class Logger {
    private let lock = NSLock()
    private var routes: [any LogRoute]

    public init(routes: [any LogRoute] = []) {
        self.routes = routes
    }

    public func addRoute(_ route: any LogRoute) {
        lock.withLock {
            routes.append(route)
        }
    }

    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> [String: String] = [:],
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        timestamp: @autoclosure () -> Date = Date()
    ) {
        let activeRoutes = enabledRoutes(for: level)
        if activeRoutes.isEmpty {
            return
        }

        let payload = LogMessage(
            level: level,
            message: message(),
            metadata: metadata(),
            fileID: fileID,
            function: function,
            line: line,
            timestamp: timestamp()
        )

        activeRoutes.forEach { $0.log(payload) }
    }

    public func logFileURL(for routeType: LogRouteType) -> URL? {
        let snapshot = lock.withLock { routes }
        let matchingFileRoute = snapshot.first { route in
            if route.routeType != routeType {
                return false
            }

            return route is any LogFileLocationProviding
        }

        return (matchingFileRoute as? any LogFileLocationProviding)?.logFileURL
    }

    public func logFilePath(for routeType: LogRouteType) -> String? {
        if let logFileURL = logFileURL(for: routeType) {
            return logFileURL.path
        }

        return nil
    }

    public func firstLogFileURL() -> URL? {
        logFileURL(for: .file)
    }

    public func firstLogFilePath() -> String? {
        logFilePath(for: .file)
    }

    private func enabledRoutes(for level: LogLevel) -> [any LogRoute] {
        let snapshot = lock.withLock { routes }
        return snapshot.filter { $0.isEnabled(for: level) }
    }
}

private extension NSLocking {
    @discardableResult
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
