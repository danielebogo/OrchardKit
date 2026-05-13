import Foundation

public enum FileLogRouteError: Error {
    case failedToCreateParentDirectory(URL, any Error)
    case parentPathIsNotDirectory(URL)
    case failedToCreateFile(URL)
    case failedToOpenFile(URL, any Error)
}
