import Foundation

/// Errors thrown while preparing file-backed logging.
public enum FileLogRouteError: Error {
    /// The route could not create the directory that should contain the log file.
    ///
    /// - Parameters:
    ///   - parentDirectoryURL: The directory URL that could not be created.
    ///   - underlyingError: The filesystem error reported by `FileManager`.
    case failedToCreateParentDirectory(
        parentDirectoryURL: URL,
        underlyingError: any Error
    )

    /// The path that should contain the log file already exists as a non-directory item.
    ///
    /// - Parameter parentDirectoryURL: The existing non-directory item URL.
    case parentPathIsNotDirectory(parentDirectoryURL: URL)

    /// The route could not create the log file.
    ///
    /// - Parameter fileURL: The log file URL that could not be created.
    case failedToCreateFile(fileURL: URL)

    /// The route could not open the log file for writing.
    ///
    /// - Parameters:
    ///   - fileURL: The log file URL that could not be opened.
    ///   - underlyingError: The filesystem error reported while opening the file.
    case failedToOpenFile(
        fileURL: URL,
        underlyingError: any Error
    )
}
