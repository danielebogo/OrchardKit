import Foundation

public final class FileLogRoute: LogRoute, LogFileLocationProviding {
    public let logFileURL: URL
    public let routeType: LogRouteType
    public let maxBytes: Int
    public let maxPendingWrites: Int
    public let verbosity: LogVerbosity

    private let fileManager: FileManager
    private let writeQueue: DispatchQueue
    private let writeQueueKey = DispatchSpecificKey<Void>()
    private let pendingWrites: DispatchSemaphore

    private var fileHandle: FileHandle?
    private var currentSize: Int = 0

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

    init(
        fileURL: URL,
        routeType: LogRouteType = .file,
        verbosity: LogVerbosity = .default,
        maxBytes: Int = 262_144,
        maxPendingWrites: Int = 256,
        fileManager: FileManager = .default,
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
        self.fileManager = fileManager
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

    public func isEnabled(
        for level: LogLevel,
        verbosity: LogVerbosity
    ) -> Bool {
        self.verbosity.includes(verbosity)
            && (level == .info || level == .error)
    }

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

        if fileManager.fileExists(
            atPath: parentDirectory.path,
            isDirectory: &isDirectory
        ) {
            if isDirectory.boolValue {
                return
            }

            throw FileLogRouteError.parentPathIsNotDirectory(
                parentDirectoryURL: parentDirectory
            )
        }

        do {
            try fileManager.createDirectory(
                at: parentDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw FileLogRouteError.failedToCreateParentDirectory(
                parentDirectoryURL: parentDirectory,
                underlyingError: error
            )
        }
    }

    private func createFileIfNeeded() throws {
        if fileManager.fileExists(atPath: logFileURL.path) {
            return
        }

        let created = fileManager.createFile(
            atPath: logFileURL.path,
            contents: Data()
        )
        if created {
            return
        }

        throw FileLogRouteError.failedToCreateFile(fileURL: logFileURL)
    }

    private func existingFileSize() -> Int {
        let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path)
        let fileSize = attributes?[.size] as? NSNumber

        return fileSize?.intValue ?? 0
    }

    private func openFileHandle() throws {
        do {
            let handle = try FileHandle(forWritingTo: logFileURL)
            try handle.seekToEnd()
            fileHandle = handle
        } catch {
            fileHandle = nil
            throw FileLogRouteError.failedToOpenFile(
                fileURL: logFileURL,
                underlyingError: error
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
