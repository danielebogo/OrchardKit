/// Identifies the kind of route that receives log messages.
public enum LogRouteType: Hashable, Sendable {
    /// The Apple unified logging route.
    case osLog
    /// The default file logging route.
    case file
    /// A caller-defined route type, useful when multiple routes of the same implementation need distinct identities.
    case custom(String)
}
