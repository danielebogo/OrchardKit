import Foundation

/// A route that can expose the file URL backing its log output.
public protocol LogFileLocationProviding {
    /// The file URL where this route writes logs.
    var logFileURL: URL { get }
}
