public enum LogVerbosity: Int, CaseIterable, Sendable {
    case `default`
    case low

    func includes(_ verbosity: LogVerbosity) -> Bool {
        verbosity.rawValue <= rawValue
    }
}
