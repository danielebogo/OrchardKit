import Foundation

/// Provides file-system operations used while preparing and writing a file log route.
struct FileLogRouteFileSystem {
    /// The file manager used to inspect paths, create directories, and read attributes.
    let fileManager: FileManager

    /// The operation used to create the log file when it does not exist.
    private let createFileAction: (String, Data?) -> Bool

    /// The operation used to create the parent directory when it does not exist.
    private let createDirectoryAction: (URL, Bool) throws -> Void

    /// The operation used to open a writable handle for the log file.
    private let openFileHandleAction: (URL) throws -> FileHandle

    /// Creates a file-system dependency wrapper for `FileLogRoute`.
    ///
    /// - Parameters:
    ///   - fileManager: The file manager used for path and directory operations.
    ///   - createFile: The operation used to create missing log files.
    ///   - createDirectory: The operation used to create missing parent directories.
    ///   - openFileHandle: The operation used to open writable file handles.
    init(
        fileManager: FileManager = .default,
        createFile: ((String, Data?) -> Bool)? = nil,
        createDirectory: ((URL, Bool) throws -> Void)? = nil,
        openFileHandle: ((URL) throws -> FileHandle)? = nil
    ) {
        self.fileManager = fileManager
        self.createFileAction = createFile ?? { path, contents in
            fileManager.createFile(
                atPath: path,
                contents: contents
            )
        }
        self.createDirectoryAction = createDirectory ?? { url, createIntermediates in
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: createIntermediates
            )
        }
        self.openFileHandleAction = openFileHandle ?? { url in
            try FileHandle(forWritingTo: url)
        }
    }

    /// Creates a file at the requested path.
    ///
    /// - Parameters:
    ///   - path: The file-system path where the log file should exist.
    ///   - contents: The initial file contents.
    /// - Returns: `true` when the file was created.
    func createFile(
        atPath path: String,
        contents: Data?
    ) -> Bool {
        createFileAction(
            path,
            contents
        )
    }

    /// Creates a directory at the requested URL.
    ///
    /// - Parameters:
    ///   - url: The directory URL that should exist before logging starts.
    ///   - createIntermediates: Whether missing intermediate directories should be created.
    /// - Throws: Any error produced while creating the directory.
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool
    ) throws {
        try createDirectoryAction(
            url,
            createIntermediates
        )
    }

    /// Opens a writable file handle for the requested URL.
    ///
    /// - Parameter url: The log file URL to open for writing.
    /// - Returns: A writable file handle positioned by the caller.
    /// - Throws: Any error produced while opening the file handle.
    func openFileHandle(forWritingTo url: URL) throws -> FileHandle {
        try openFileHandleAction(url)
    }
}
