import Foundation

/// A fully materialized log entry sent to enabled routes.
public struct LogMessage: Equatable, Sendable {
    /// The severity of the event.
    public let level: LogLevel
    /// The verbosity requested by the caller.
    public let verbosity: LogVerbosity
    /// The caller-provided message text.
    public let message: String
    /// Additional key-value details attached to the message.
    public let metadata: [String: String]
    /// The Swift file identifier captured at the log call site.
    public let fileID: String
    /// The function name captured at the log call site.
    public let function: String
    /// The source line captured at the log call site.
    public let line: UInt
    /// The time associated with the log entry.
    public let timestamp: Date

    /// Creates a materialized log entry.
    ///
    /// - Parameters:
    ///   - level: The severity of the event.
    ///   - verbosity: The verbosity requested by the caller.
    ///   - message: The message text to route.
    ///   - metadata: Additional key-value details to render with the message.
    ///   - fileID: The Swift file identifier for the call site.
    ///   - function: The function name for the call site.
    ///   - line: The source line for the call site.
    ///   - timestamp: The time associated with the entry.
    public init(
        level: LogLevel,
        verbosity: LogVerbosity = .default,
        message: String,
        metadata: [String: String] = [:],
        fileID: String,
        function: String,
        line: UInt,
        timestamp: Date = Date()
    ) {
        self.level = level
        self.verbosity = verbosity
        self.message = message
        self.metadata = metadata
        self.fileID = fileID
        self.function = function
        self.line = line
        self.timestamp = timestamp
    }

    /// A stable text representation suitable for route output.
    ///
    /// Metadata is sorted by key before rendering so repeated messages are deterministic.
    public var renderedMessage: String {
        let metadataDescription = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let metadataSuffix = metadataDescription.isEmpty ? "" : " | \(metadataDescription)"

        return "[\(level.rawValue.uppercased())] \(message)\(metadataSuffix) (\(fileID):\(line) \(function))"
    }
}
