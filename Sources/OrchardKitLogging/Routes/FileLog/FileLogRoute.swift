import Foundation

/// A route that writes selected log messages to a UTF-8 text file.
///
/// The route writes on a background utility queue, accepts `.info` and `.error` messages, truncates the file when the
/// next write would exceed `maxBytes`, and drops new messages when `maxPendingWrites` are already queued.
public final class FileLogRoute: LogRoute, LogFileLocationProviding {
    /// The file URL where messages are written.
    public let logFileURL: URL
    /// The route identity used for logger lookups.
    public let routeType: LogRouteType
    /// The maximum file size in bytes before truncation is attempted.
    ///
    /// This value must be greater than zero; invalid values trigger a precondition failure.
    public let maxBytes: Int
    /// The maximum number of queued writes allowed before new messages are dropped.
    ///
    /// This value must be greater than zero; invalid values trigger a precondition failure.
    public let maxPendingWrites: Int
    /// The maximum verbosity this route accepts.
    public let verbosity: LogVerbosity

    private let fileSystem: FileLogRouteFileSystem
    private let writeQueue: DispatchQueue
    private let writeQueueKey = DispatchSpecificKey<Void>()
    private let pendingWrites: DispatchSemaphore

    private var fileHandle: FileHandle?
    private var currentSize: Int = 0

    /// Creates a file route that writes to a specific URL.
    ///
    /// The initializer creates the parent directory and log file when needed, opens the file for appending, and throws if
    /// those setup steps fail. `maxBytes` and `maxPendingWrites` must be greater than zero; invalid values trigger a
    /// precondition failure rather than throwing.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL to write.
    ///   - routeType: The identity used to find this route later.
    ///   - verbosity: The maximum verbosity this route accepts.
    ///   - maxBytes: The maximum file size in bytes before truncation is attempted.
    ///   - maxPendingWrites: The maximum number of queued writes allowed before new messages are dropped.
    ///   - fileManager: The file manager used for directory and file operations.
    /// - Throws: A `FileLogRouteError` when the parent directory, log file, or writable file handle cannot be prepared.
    public convenience init(
        fileURL: URL,
        routeType: LogRouteType = .file,
        verbosity: LogVerbosity = .default,
        maxBytes: Int = 262_144,
        maxPendingWrites: Int = 256,
        fileManager: FileManager = .default
    ) throws {
        try self.init(
            fileURL: fileURL,
            routeType: routeType,
            verbosity: verbosity,
            maxBytes: maxBytes,
            maxPendingWrites: maxPendingWrites,
            fileManager: fileManager,
            writeQueue: Self.makeWriteQueue()
        )
    }

    convenience init(
        fileURL: URL,
        routeType: LogRouteType = .file,
        verbosity: LogVerbosity = .default,
        maxBytes: Int = 262_144,
        maxPendingWrites: Int = 256,
        fileManager: FileManager = .default,
        writeQueue: DispatchQueue
    ) throws {
        try self.init(
            fileURL: fileURL,
            routeType: routeType,
            verbosity: verbosity,
            maxBytes: maxBytes,
            maxPendingWrites: maxPendingWrites,
            fileSystem: FileLogRouteFileSystem(fileManager: fileManager),
            writeQueue: writeQueue
        )
    }

    init(
        fileURL: URL,
        routeType: LogRouteType = .file,
        verbosity: LogVerbosity = .default,
        maxBytes: Int = 262_144,
        maxPendingWrites: Int = 256,
        fileSystem: FileLogRouteFileSystem,
        writeQueue: DispatchQueue
    ) throws {
        precondition(maxBytes > 0, "maxBytes must be greater than zero.")
        precondition(
            maxPendingWrites > 0,
            "maxPendingWrites must be greater than zero."
        )

        self.logFileURL = fileURL
        self.routeType = routeType
        self.verbosity = verbosity
        self.maxBytes = maxBytes
        self.maxPendingWrites = maxPendingWrites
        self.fileSystem = fileSystem
        self.writeQueue = writeQueue
        self.pendingWrites = DispatchSemaphore(value: maxPendingWrites)
        self.writeQueue.setSpecific(
            key: writeQueueKey,
            value: ()
        )

        try writeQueue.sync {
            try prepareFileIfNeeded()
        }
    }

    /// Creates a file route using the package default directory and the provided filename.
    ///
    /// `maxBytes` and `maxPendingWrites` must be greater than zero; invalid values trigger a precondition failure rather
    /// than throwing.
    ///
    /// - Parameters:
    ///   - fileName: The filename appended to the default log directory.
    ///   - routeType: The identity used to find this route later.
    ///   - verbosity: The maximum verbosity this route accepts.
    ///   - maxBytes: The maximum file size in bytes before truncation is attempted.
    ///   - maxPendingWrites: The maximum number of queued writes allowed before new messages are dropped.
    ///   - fileManager: The file manager used for directory and file operations.
    /// - Throws: A `FileLogRouteError` when the parent directory, log file, or writable file handle cannot be prepared.
    public convenience init(
        fileName: String = "orchardkit-logs.txt",
        routeType: LogRouteType = .file,
        verbosity: LogVerbosity = .default,
        maxBytes: Int = 262_144,
        maxPendingWrites: Int = 256,
        fileManager: FileManager = .default
    ) throws {
        try self.init(
            fileURL: Self.defaultFileURL(
                fileName: fileName,
                fileManager: fileManager
            ),
            routeType: routeType,
            verbosity: verbosity,
            maxBytes: maxBytes,
            maxPendingWrites: maxPendingWrites,
            fileManager: fileManager
        )
    }

    /// Returns the default URL for a log filename.
    ///
    /// The caches directory is preferred; the file manager's temporary directory is used when no caches directory is
    /// available.
    ///
    /// - Parameters:
    ///   - fileName: The filename to append to the selected base directory.
    ///   - fileManager: The file manager used to locate the base directory.
    public static func defaultFileURL(
        fileName: String = "orchardkit-logs.txt",
        fileManager: FileManager = .default
    ) -> URL {
        let baseDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return baseDirectory.appendingPathComponent(fileName)
    }

    /// Returns whether this route should receive a message with the requested level and verbosity.
    ///
    /// File logging currently accepts `.info` and `.error` messages when the route verbosity includes the requested
    /// verbosity.
    ///
    /// - Parameters:
    ///   - level: The severity of the candidate message.
    ///   - verbosity: The verbosity requested by the log call.
    public func isEnabled(
        for level: LogLevel
    ) -> Bool {
        level == .info || level == .error
    }

    public func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        self.verbosity.includes(verbosity)
            && isEnabled(for: level)
    }

    /// Queues a message for file output.
    ///
    /// If `maxPendingWrites` messages are already queued, the message is dropped instead of blocking the caller.
    public func log(_ message: LogMessage) {
        if pendingWrites.wait(timeout: .now()) == .timedOut {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            defer { self?.pendingWrites.signal() }
            self?.write(message)
        }

        writeQueue.async(execute: workItem)
    }

    func flushForTesting() {
        if DispatchQueue.getSpecific(key: writeQueueKey) != nil {
            return
        }

        writeQueue.sync {}
    }

    private func write(_ message: LogMessage) {
        let renderedMessage = "\(message.renderedMessage)\n"

        if let data = renderedMessage.data(using: .utf8) {
            append(data)
        }
    }

    private func append(_ data: Data) {
        if data.count > maxBytes {
            return
        }

        if currentSize + data.count > maxBytes {
            let truncateSucceeded = truncateFile()
            if !truncateSucceeded {
                return
            }

            if currentSize + data.count > maxBytes {
                return
            }
        }

        if fileHandle == nil {
            try? openFileHandle()
        }

        if let fileHandle {
            do {
                try fileHandle.write(contentsOf: data)
                currentSize += data.count
            } catch {
                closeFileHandle()
                currentSize = existingFileSize()
            }
        }
    }

    private func prepareFileIfNeeded() throws {
        try createParentDirectoryIfNeeded()
        try createFileIfNeeded()
        currentSize = existingFileSize()
        try openFileHandle()
    }

    private func createParentDirectoryIfNeeded() throws {
        let parentDirectory = logFileURL.deletingLastPathComponent()
        var isDirectory = ObjCBool(false)

        if fileSystem.fileManager.fileExists(
            atPath: parentDirectory.path,
            isDirectory: &isDirectory
        ) {
            if isDirectory.boolValue {
                return
            }

            throw FileLogRouteError.parentPathIsNotDirectory(parentDirectory)
        }

        do {
            try fileSystem.createDirectory(
                at: parentDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw FileLogRouteError.failedToCreateParentDirectory(
                parentDirectory,
                error
            )
        }
    }

    private func createFileIfNeeded() throws {
        if fileSystem.fileManager.fileExists(atPath: logFileURL.path) {
            return
        }

        let created = fileSystem.createFile(
            atPath: logFileURL.path,
            contents: Data()
        )
        if created {
            return
        }

        throw FileLogRouteError.failedToCreateFile(logFileURL)
    }

    private func existingFileSize() -> Int {
        let attributes = try? fileSystem.fileManager.attributesOfItem(atPath: logFileURL.path)
        let fileSize = attributes?[.size] as? NSNumber

        return fileSize?.intValue ?? 0
    }

    private func openFileHandle() throws {
        do {
            let handle = try fileSystem.openFileHandle(forWritingTo: logFileURL)
            try handle.seekToEnd()
            fileHandle = handle
        } catch {
            fileHandle = nil
            throw FileLogRouteError.failedToOpenFile(
                logFileURL,
                error
            )
        }
    }

    private func closeFileHandle() {
        if let fileHandle {
            try? fileHandle.close()
            self.fileHandle = nil
        }
    }

    private func truncateFile() -> Bool {
        closeFileHandle()

        do {
            try Data().write(
                to: logFileURL,
                options: .atomic
            )
        } catch {
            currentSize = existingFileSize()
            try? openFileHandle()
            return false
        }

        currentSize = existingFileSize()
        try? openFileHandle()
        return true
    }

    private static func makeWriteQueue() -> DispatchQueue {
        DispatchQueue(
            label: "com.orchardkit.logging.file-route",
            qos: .utility
        )
    }
}
