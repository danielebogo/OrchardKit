import Foundation

/// An error thrown while preparing a file-backed logging route.
public enum FileLogRouteError: Error {
    /// The parent directory could not be created.
    case failedToCreateParentDirectory(URL, any Error)
    /// The parent path exists but is not a directory.
    case parentPathIsNotDirectory(URL)
    /// The log file could not be created.
    case failedToCreateFile(URL)
    /// The log file could not be opened for writing.
    case failedToOpenFile(URL, any Error)
}
