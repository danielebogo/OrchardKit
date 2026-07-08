import Foundation

/// Routes log calls to enabled destinations.
///
/// The logger is safe to update from multiple threads. Message, metadata, and timestamp autoclosures are evaluated only
/// when at least one configured route accepts the requested level and verbosity.
public final class Logger {
    private let lock = NSLock()
    private var routes: [any LogRoute]

    /// Creates a logger with the routes that should receive messages.
    ///
    /// - Parameter routes: The initial destinations for log output.
    public init(routes: [any LogRoute] = []) {
        self.routes = routes
    }

    /// Adds a route that can receive future log messages.
    ///
    /// - Parameter route: The destination to append to this logger.
    public func addRoute(_ route: any LogRoute) {
        lock.withLock {
            routes.append(route)
        }
    }

    /// Sends a message to every route enabled for the requested level and verbosity.
    ///
    /// Message, metadata, and timestamp providers are evaluated only when at least one route will receive the message.
    ///
    /// - Parameters:
    ///   - level: The severity of the event.
    ///   - message: A lazily evaluated message string.
    ///   - verbosity: The verbosity requested for this message.
    ///   - metadata: Lazily evaluated key-value details attached to the message.
    ///   - fileID: The Swift file identifier for the call site.
    ///   - function: The function name for the call site.
    ///   - line: The source line for the call site.
    ///   - timestamp: A lazily evaluated timestamp for the message.
    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        verbosity: LogVerbosity = .default,
        metadata: @autoclosure () -> [String: String] = [:],
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line,
        timestamp: @autoclosure () -> Date = Date()
    ) {
        let activeRoutes = enabledRoutes(
            for: level,
            verbosity: verbosity
        )
        if activeRoutes.isEmpty {
            return
        }

        let payload = LogMessage(
            level: level,
            verbosity: verbosity,
            message: message(),
            metadata: metadata(),
            fileID: fileID,
            function: function,
            line: line,
            timestamp: timestamp()
        )

        activeRoutes.forEach { $0.log(payload) }
    }

    /// Returns the log file URL for the first file-backed route with the requested route type.
    ///
    /// - Parameter routeType: The route type to match before reading the log file location.
    /// - Returns: The matching route's log file URL, or `nil` when no matching file-backed route exists.
    public func logFileURL(for routeType: LogRouteType) -> URL? {
        logFileURL { route in
            route.routeType == routeType
        }
    }

    /// Returns the log file path for the first file-backed route with the requested route type.
    ///
    /// - Parameter routeType: The route type to match before reading the log file location.
    /// - Returns: The matching route's log file path, or `nil` when no matching file-backed route exists.
    public func logFilePath(for routeType: LogRouteType) -> String? {
        if let logFileURL = logFileURL(for: routeType) {
            return logFileURL.path
        }

        return nil
    }

    /// Returns the first available file-backed route URL.
    ///
    /// - Returns: The first configured route's log file URL, or `nil` when no route provides a file location.
    public func firstLogFileURL() -> URL? {
        logFileURL { _ in true }
    }

    /// Returns the first available file-backed route path.
    ///
    /// - Returns: The first configured route's log file path, or `nil` when no route provides a file location.
    public func firstLogFilePath() -> String? {
        if let logFileURL = firstLogFileURL() {
            return logFileURL.path
        }

        return nil
    }

    private func enabledRoutes(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> [any LogRoute] {
        let snapshot = lock.withLock { routes }
        return snapshot.filter {
            $0.isEnabled(
                for: level,
                verbosity: verbosity
            )
        }
    }

    /// Returns the first log file URL from a route accepted by the predicate.
    ///
    /// - Parameter isMatchingRoute: A predicate that selects routes eligible for file lookup.
    /// - Returns: The first eligible route's log file URL, or `nil` when no eligible route provides one.
    private func logFileURL(
        matching isMatchingRoute: (any LogRoute) -> Bool
    ) -> URL? {
        let snapshot = lock.withLock { routes }
        let matchingFileRoute = snapshot.first { route in
            if !isMatchingRoute(route) {
                return false
            }

            return route is any LogFileLocationProviding
        }

        return (matchingFileRoute as? any LogFileLocationProviding)?.logFileURL
    }
}
