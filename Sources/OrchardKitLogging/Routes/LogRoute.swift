/// A destination that receives routed log messages.
public protocol LogRoute {
    var routeType: LogRouteType { get }
    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool
    func log(_ message: LogMessage)
}

public extension LogRoute {
    func isEnabled(for level: LogLevel) -> Bool {
        isEnabled(
            for: level,
            verbosity: .default
        )
    }

    var routeType: LogRouteType {
        .custom(String(describing: type(of: self)))
    }

    func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        verbosity == .default
    }
}
