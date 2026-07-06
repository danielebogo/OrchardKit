/// A severity level for a log message.
public enum LogLevel: String, CaseIterable, Sendable {
    /// A notable event that belongs in normal operational logs.
    case notice
    /// Informational progress or lifecycle details.
    case info
    /// Diagnostic details useful while debugging.
    case debug
    /// Highly detailed diagnostic output.
    case trace
    /// A recoverable problem that may need attention.
    case warning
    /// A failure that prevented an operation from completing.
    case error
    /// A serious fault that indicates corrupted state or a system-level failure.
    case fault
    /// A critical failure that may require stopping the current flow.
    case critical
}
