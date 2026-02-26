import Foundation

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
