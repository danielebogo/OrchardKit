/// A destination that receives routed log messages.
public protocol LogRoute {
    var routeType: LogRouteType { get }
    func isEnabled(for level: LogLevel) -> Bool
    func log(_ message: LogMessage)
}

public extension LogRoute {
    var routeType: LogRouteType {
        .custom(String(describing: type(of: self)))
    }

    func isEnabled(for level: LogLevel) -> Bool {
        true
    }
}
