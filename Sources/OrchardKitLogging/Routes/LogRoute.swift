/// A destination that receives routed log messages.
public protocol LogRoute {
    /// The stable route kind used for route-specific lookups.
    var routeType: LogRouteType { get }

    /// Returns whether this route accepts logs at the supplied level.
    ///
    /// - Parameter level: The log level being evaluated.
    /// - Returns: `true` when the route should receive logs at `level`.
    func isEnabled(for level: LogLevel) -> Bool

    /// Returns whether this route accepts logs for the supplied level and verbosity.
    ///
    /// - Parameters:
    ///   - level: The log level being evaluated.
    ///   - verbosity: The verbosity requested for the log event.
    /// - Returns: `true` when the route should receive matching log events.
    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool

    /// Sends a prepared log message to the route.
    ///
    /// - Parameter message: The message created after route enablement succeeds.
    func log(_ message: LogMessage)
}

/// Provides default route behavior for custom log routes.
public extension LogRoute {
    var routeType: LogRouteType {
        .custom(String(describing: type(of: self)))
    }

    /// Returns whether this route should receive a message with the requested level and verbosity.
    ///
    /// The default implementation accepts only `.default` verbosity and does not filter by level.
    ///
    /// - Parameters:
    ///   - level: The severity of the candidate message.
    ///   - verbosity: The verbosity requested by the log call.
    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        isEnabled(for: level)
            && verbosity == .default
    }
}
