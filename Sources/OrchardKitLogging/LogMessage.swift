import Foundation

public struct LogMessage: Equatable, Sendable {
    public let level: LogLevel
    public let message: String
    public let metadata: [String: String]
    public let fileID: String
    public let function: String
    public let line: UInt
    public let timestamp: Date

    public init(
        level: LogLevel,
        message: String,
        metadata: [String: String] = [:],
        fileID: String,
        function: String,
        line: UInt,
        timestamp: Date = Date()
    ) {
        self.level = level
        self.message = message
        self.metadata = metadata
        self.fileID = fileID
        self.function = function
        self.line = line
        self.timestamp = timestamp
    }

    public var renderedMessage: String {
        let metadataDescription = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let metadataSuffix = metadataDescription.isEmpty ? "" : " | \(metadataDescription)"

        return "[\(level.rawValue.uppercased())] \(message)\(metadataSuffix) (\(fileID):\(line) \(function))"
    }
}
