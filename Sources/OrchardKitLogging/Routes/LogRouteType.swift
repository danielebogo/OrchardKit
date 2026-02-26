public enum LogRouteType: Hashable, Sendable {
    case osLog
    case file
    case custom(String)
}
