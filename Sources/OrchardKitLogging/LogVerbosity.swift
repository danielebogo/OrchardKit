/// A route filtering level for deciding which messages are delivered.
///
/// A route configured with `.default` receives only default-verbosity messages. A route configured with `.low` receives
/// both default and low-verbosity messages.
public enum LogVerbosity: Int, CaseIterable, Sendable {
    /// The normal verbosity used for operational logs.
    case `default`
    /// A lower-priority verbosity for logs that only more verbose routes should receive.
    case low

    func includes(_ verbosity: LogVerbosity) -> Bool {
        verbosity.rawValue <= rawValue
    }
}
