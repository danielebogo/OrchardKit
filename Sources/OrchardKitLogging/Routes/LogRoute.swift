/// A destination that receives routed log messages.
public protocol LogRoute {
    /// The identity used to look up this route in a logger.
    var routeType: LogRouteType { get }
    /// Returns whether this route should receive a message with the requested level and verbosity.
    ///
    /// - Parameters:
    ///   - level: The severity of the candidate message.
    ///   - verbosity: The verbosity requested by the log call.
    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool
    /// Receives a materialized message for route-specific output.
    func log(_ message: LogMessage)
}

/// Provides default route behavior for custom log routes.
public extension LogRoute {
    /// Returns whether this route should receive a default-verbosity message with the requested level.
    ///
    /// - Parameter level: The severity of the candidate message.
    func isEnabled(for level: LogLevel) -> Bool {
        isEnabled(
            for: level,
            verbosity: .default
        )
    }

    /// The default route identity based on the conforming type name.
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
        verbosity == .default
    }
}
