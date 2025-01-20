import Foundation
import OSLog
import Combine

enum PlaybackError: Error {
    case invalidToken
    case networkError(Error)
    case serverError(String)
    case invalidURL
    case downloadError(String)
}

/// Protocol defining the interface for persisting download states
protocol DownloadStatePersistable {
    func saveStates(_ states: [String: PlaybackService.DownloadState]) throws
    func loadStates() throws -> [String: PlaybackService.DownloadState]
}

/// Concrete implementation of download state persistence using UserDefaults
class UserDefaultsDownloadStatePersistence: DownloadStatePersistable {
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "DownloadStatePersistence")
    private let storageKey = "downloadStates"
    
    func saveStates(_ states: [String: PlaybackService.DownloadState]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(states)
        UserDefaults.standard.set(data, forKey: storageKey)
        UserDefaults.standard.synchronize()
        logger.debug("Saved \(states.count) download states")
    }
    
    func loadStates() throws -> [String: PlaybackService.DownloadState] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            logger.debug("No saved download states found")
            return [:]
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([String: PlaybackService.DownloadState].self, from: data)
    }
}

@MainActor
class PlaybackService: NSObject, ObservableObject {
    static let shared = PlaybackService()
    private let authService = AuthenticationService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "PlaybackService")
    private let statePersistence: DownloadStatePersistable
    
    @Published private(set) var activeDownloads: [String: DownloadState] = [:] {
        didSet {
            Task { @MainActor in
                do {
                    try self.statePersistence.saveStates(self.activeDownloads)
                } catch {
                    self.logger.error("Failed to save download states: \(error.localizedDescription)")
                }
            }
        }
    }
    private var downloadTasks: [URLSessionDownloadTask: String] = [:]
    private var downloadContinuations: [String: CheckedContinuation<URL, Error>] = [:]
    private var processingTasks: Set<Int> = []
    
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.jellyroll.app.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return URLSession(configuration: config, delegate: self, delegateQueue: queue)
    }()
    
    private override init() {
        self.statePersistence = UserDefaultsDownloadStatePersistence()
        super.init()
        do {
            self.activeDownloads = try statePersistence.loadStates()
        } catch {
            logger.error("Failed to load download states: \(error.localizedDescription)")
            self.activeDownloads = [:]
        }
    }
    
    struct DownloadState: Codable {
        var progress: Double
        var status: DownloadStatus
        var localURL: URL?
        
        enum CodingKeys: String, CodingKey {
            case progress
            case status
            case localURL
        }
        
        init(progress: Double, status: DownloadStatus, localURL: URL? = nil) {
            self.progress = progress
            self.status = status
            self.localURL = localURL
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            progress = try container.decode(Double.self, forKey: .progress)
            status = try container.decode(DownloadStatus.self, forKey: .status)
            if let relativePath = try container.decodeIfPresent(String.self, forKey: .localURL) {
                // Convert relative path to absolute URL
                if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    localURL = documentsURL.appendingPathComponent(relativePath)
                }
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(progress, forKey: .progress)
            try container.encode(status, forKey: .status)
            if let url = localURL,
               let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                // Store relative path from Documents directory
                let relativePath = url.path.replacingOccurrences(of: documentsURL.path + "/", with: "")
                try container.encode(relativePath, forKey: .localURL)
            }
        }
    }
    
    enum DownloadStatus: Codable, Equatable {
        case notDownloaded
        case downloading
        case downloaded
        case failed(String)
        
        enum CodingKeys: String, CodingKey {
            case type
            case errorMessage
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "notDownloaded":
                self = .notDownloaded
            case "downloading":
                self = .downloading
            case "downloaded":
                self = .downloaded
            case "failed":
                let message = try container.decode(String.self, forKey: .errorMessage)
                self = .failed(message)
            default:
                self = .notDownloaded
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .notDownloaded:
                try container.encode("notDownloaded", forKey: .type)
            case .downloading:
                try container.encode("downloading", forKey: .type)
            case .downloaded:
                try container.encode("downloaded", forKey: .type)
            case .failed(let message):
                try container.encode("failed", forKey: .type)
                try container.encode(message, forKey: .errorMessage)
            }
        }
        
        static func == (lhs: DownloadStatus, rhs: DownloadStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notDownloaded, .notDownloaded):
                return true
            case (.downloading, .downloading):
                return true
            case (.downloaded, .downloaded):
                return true
            case (.failed(let lhsMessage), .failed(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    /// Helper method to construct media stream URLs with proper authentication and parameters
    private func constructMediaStreamURL(for itemId: String, token: AuthenticationToken, baseURL: URL) throws -> URL {
        let streamURL = baseURL
            .appendingPathComponent("Videos")
            .appendingPathComponent(itemId)
            .appendingPathComponent("stream")
        
        var components = URLComponents(url: streamURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "static", value: "true"),
            URLQueryItem(name: "api_key", value: token.accessToken),
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "MaxAudioChannels", value: "2"),
            URLQueryItem(name: "AudioSampleRate", value: "44100"),
            URLQueryItem(name: "StartTimeTicks", value: "0")
        ]
        
        guard let finalURL = components.url else {
            throw PlaybackError.invalidURL
        }
        
        return finalURL
    }

    /// Helper method to get authenticated server base URL
    private func getAuthenticatedBaseURL() throws -> (baseURL: URL, token: AuthenticationToken) {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            logger.error("Failed to get server configuration or token")
            throw PlaybackError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let baseURL = URL(string: urlString) else {
            logger.error("Invalid base URL: \(urlString)")
            throw PlaybackError.invalidURL
        }
        
        return (baseURL, token)
    }

    func getPlaybackURL(for item: MediaItem) async throws -> URL {
        let (baseURL, token) = try getAuthenticatedBaseURL()
        return try constructMediaStreamURL(for: item.id, token: token, baseURL: baseURL)
    }
    
    func updatePlaybackProgress(for item: MediaItem, positionTicks: Int64) async throws {
        let (baseURL, token) = try getAuthenticatedBaseURL()
        
        // Construct the playback progress URL
        let progressURL = baseURL
            .appendingPathComponent("Users")
            .appendingPathComponent(token.user.id)
            .appendingPathComponent("PlayingItems")
            .appendingPathComponent(item.id)
            .appendingPathComponent("Progress")
        
        var request = URLRequest(url: progressURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        let progressData = [
            "PositionTicks": positionTicks
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: progressData)
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaybackError.serverError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                throw PlaybackError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
        } catch {
            logger.error("Error updating playback progress: \(error.localizedDescription)")
            throw PlaybackError.networkError(error)
        }
    }
    
    func downloadMovie(item: MediaItem) async throws -> URL {
        self.logger.debug("Starting download for item: \(item.id) - \(item.name)")
        let (baseURL, token) = try getAuthenticatedBaseURL()
        return try constructMediaStreamURL(for: item.id, token: token, baseURL: baseURL)
    }
    
    func getDownloadState(for itemId: String) -> DownloadState? {
        return activeDownloads[itemId]
    }
    
    func deleteDownload(itemId: String) throws {
        guard let state = activeDownloads[itemId],
              let localURL = state.localURL else {
            return
        }
        
        try FileManager.default.removeItem(at: localURL)
        activeDownloads[itemId] = nil
    }
    
    private func getDownloadsDirectory() throws -> URL {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PlaybackError.downloadError("Could not access Documents directory")
        }
        
        let downloadsURL = documentsURL.appendingPathComponent("Downloads", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: downloadsURL.path) {
            try fileManager.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
            
            // Add a .nomedia file to prevent media scanning
            let noMediaURL = downloadsURL.appendingPathComponent(".nomedia")
            if !fileManager.fileExists(atPath: noMediaURL.path) {
                try Data().write(to: noMediaURL)
            }
            
            // Set directory to be excluded from backup
            var urlToExclude = downloadsURL
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try urlToExclude.setResourceValues(resourceValues)
        }
        
        return downloadsURL
    }
    
    func getDownloadedURL(for itemId: String) -> URL? {
        guard let state = activeDownloads[itemId],
              case .downloaded = state.status,
              let localURL = state.localURL,
              FileManager.default.fileExists(atPath: localURL.path),
              FileManager.default.isReadableFile(atPath: localURL.path) else {
            return nil
        }
        return localURL
    }
    
    func cancelDownload(itemId: String) {
        self.logger.debug("Cancelling download for item: \(itemId)")
        
        // Find and cancel the download task
        if let task = downloadTasks.first(where: { $0.value == itemId })?.key {
            task.cancel()
            downloadTasks.removeValue(forKey: task)
        }
        
        // Create a temporary URL for cancellation
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let tempURL = documentsPath.appendingPathComponent("cancelled")
            // Resume with a dummy URL to complete the async operation without error
            downloadContinuations[itemId]?.resume(returning: tempURL)
        }
        downloadContinuations.removeValue(forKey: itemId)
        
        // Remove the download state completely
        activeDownloads.removeValue(forKey: itemId)
        
        // Clean up any processing tasks
        processingTasks.removeAll()
        
        self.logger.debug("Download cancelled for item: \(itemId)")
    }
    
    private func getItemId(for task: URLSessionDownloadTask) -> String? {
        return downloadTasks[task]
    }
}

// MARK: - URLSessionDownloadDelegate
extension PlaybackService: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Copy the file synchronously first, before any async operations
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.copyItem(at: location, to: tempFile)
        } catch {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.logger.error("[Download] Failed to copy temporary file: \(error)")
            }
            return
        }
        
        // Now proceed with async operations using our safely copied file
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.logger.debug("[Download] Starting download completion process")
            
            guard let itemId = self.getItemId(for: downloadTask) else {
                self.logger.error("[Download] Failed to get itemId for task: \(downloadTask.taskIdentifier)")
                try? fileManager.removeItem(at: tempFile)
                return
            }
            
            // Check if this task was cancelled
            if !self.downloadTasks.contains(where: { $0.key == downloadTask }) {
                self.logger.debug("[Download] Task was cancelled, skipping processing")
                try? fileManager.removeItem(at: tempFile)
                return
            }
            
            self.processingTasks.insert(downloadTask.taskIdentifier)
            
            self.logger.debug("[Download] Processing item: \(itemId)")
            self.logger.debug("[Download] Temporary file location: \(tempFile.path)")
            
            do {
                self.logger.debug("[Files] Starting file operations")
                
                // Get the app's Documents directory
                guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    self.logger.error("[Files] Could not access Documents directory")
                    throw PlaybackError.downloadError("Could not access Documents directory")
                }
                
                self.logger.debug("[Files] Documents path: \(documentsPath.path)")
                
                // Create downloads directory
                let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
                self.logger.debug("[Files] Downloads path: \(downloadsPath.path)")
                
                // Create the directory if it doesn't exist
                do {
                    self.logger.debug("[Files] Creating Downloads directory")
                    try fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true, attributes: nil)
                    self.logger.debug("[Files] Downloads directory ready")
                } catch {
                    self.logger.error("[Files] Failed to create Downloads directory: \(error.localizedDescription)")
                    throw PlaybackError.downloadError("Failed to create Downloads directory: \(error.localizedDescription)")
                }
                
                // Create the destination URL
                let destinationURL = downloadsPath.appendingPathComponent("\(itemId).mp4")
                self.logger.debug("[Files] Target path: \(destinationURL.path)")
                
                // Handle existing file
                if fileManager.fileExists(atPath: destinationURL.path) {
                    self.logger.debug("[Files] Removing existing file")
                    do {
                        try fileManager.removeItem(at: destinationURL)
                        self.logger.debug("[Files] Existing file removed")
                    } catch {
                        self.logger.error("[Files] Failed to remove existing file: \(error.localizedDescription)")
                        throw PlaybackError.downloadError("Failed to remove existing file: \(error.localizedDescription)")
                    }
                }
                
                // Move file from our temporary location to final destination
                do {
                    self.logger.debug("[Files] Starting file move")
                    self.logger.debug("[Files] Checking temporary file at: \(tempFile.path)")
                    self.logger.debug("[Files] Temporary file exists: \(fileManager.fileExists(atPath: tempFile.path))")
                    
                    if let sourceAttrs = try? fileManager.attributesOfItem(atPath: tempFile.path) {
                        let sourceSize = sourceAttrs[.size] as? UInt64 ?? 0
                        self.logger.debug("[Files] Source file size: \(sourceSize) bytes")
                    }
                    
                    try fileManager.moveItem(at: tempFile, to: destinationURL)
                    self.logger.debug("[Files] File move completed")
                    
                    if let destAttrs = try? fileManager.attributesOfItem(atPath: destinationURL.path) {
                        let destSize = destAttrs[.size] as? UInt64 ?? 0
                        self.logger.debug("[Files] Destination file size: \(destSize) bytes")
                    }
                } catch {
                    self.logger.error("[Files] Move failed: \(error.localizedDescription)")
                    throw PlaybackError.downloadError("Failed to move downloaded file: \(error.localizedDescription)")
                }
                
                // Verify file
                self.logger.debug("[Files] Verifying file")
                guard fileManager.fileExists(atPath: destinationURL.path),
                      let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path),
                      let fileSize = attributes[.size] as? UInt64,
                      fileSize > 0 else {
                    self.logger.error("[Files] Verification failed")
                    self.logger.error("[Files] File exists: \(fileManager.fileExists(atPath: destinationURL.path))")
                    if let attrs = try? fileManager.attributesOfItem(atPath: destinationURL.path) {
                        self.logger.error("[Files] File size: \(attrs[.size] as? UInt64 ?? 0) bytes")
                    }
                    throw PlaybackError.downloadError("File verification failed - file may be empty or corrupted")
                }
                
                self.logger.debug("[Files] Verification successful - size: \(fileSize) bytes")
                
                // Update state
                self.logger.debug("[Download] Updating download state")
                self.activeDownloads[itemId] = DownloadState(progress: 1.0, status: .downloaded, localURL: destinationURL)
                self.downloadContinuations[itemId]?.resume(returning: destinationURL)
                self.downloadTasks.removeValue(forKey: downloadTask)
                self.downloadContinuations.removeValue(forKey: itemId)
                
                self.logger.debug("[Download] Process completed successfully")
            } catch {
                self.logger.error("[Download] Error: \(error.localizedDescription)")
                if let playbackError = error as? PlaybackError {
                    self.logger.error("[Download] PlaybackError: \(String(describing: playbackError))")
                    let errorMessage: String
                    switch playbackError {
                    case .downloadError(let message):
                        errorMessage = message
                    case .invalidToken:
                        errorMessage = "Invalid token"
                    case .networkError(let err):
                        errorMessage = err.localizedDescription
                    case .serverError(let message):
                        errorMessage = message
                    case .invalidURL:
                        errorMessage = "Invalid URL"
                    }
                    self.activeDownloads[itemId] = DownloadState(progress: 0, status: .failed(errorMessage))
                    self.downloadContinuations[itemId]?.resume(throwing: playbackError)
                } else {
                    self.logger.error("[Download] System error: \(error)")
                    let errorMessage = error.localizedDescription
                    self.activeDownloads[itemId] = DownloadState(progress: 0, status: .failed(errorMessage))
                    self.downloadContinuations[itemId]?.resume(throwing: PlaybackError.downloadError(errorMessage))
                }
                self.downloadTasks.removeValue(forKey: downloadTask)
                self.downloadContinuations.removeValue(forKey: itemId)
            }
            
            self.processingTasks.remove(downloadTask.taskIdentifier)
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let itemId = self.getItemId(for: downloadTask) else { return }
            
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.logger.debug("Download progress for \(itemId): \(Int(progress * 100))% (\(totalBytesWritten)/\(totalBytesExpectedToWrite) bytes)")
            
            if var state = self.activeDownloads[itemId] {
                state.progress = progress
                self.activeDownloads[itemId] = state
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask else { return }
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            // Wait for any ongoing processing to complete
            while self.processingTasks.contains(downloadTask.taskIdentifier) {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                self.logger.debug("[Download] Waiting for processing to complete for task \(downloadTask.taskIdentifier)")
            }
            
            guard let itemId = self.getItemId(for: downloadTask) else { return }
            
            if let error = error {
                self.logger.debug("Download task \(downloadTask.taskIdentifier) ended with error: \(error.localizedDescription)")
                
                // Check if this was a cancellation
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    self.logger.debug("Download was cancelled by user")
                    // Don't set any error state for cancellation
                    self.downloadTasks.removeValue(forKey: downloadTask)
                    self.downloadContinuations.removeValue(forKey: itemId)
                    return
                }
                
                // Handle other errors
                self.logger.error("Download task \(downloadTask.taskIdentifier) failed with error: \(error.localizedDescription)")
                self.logger.error("URLSession error type: \(type(of: error))")
                self.logger.error("Full error details: \(error)")
                
                let wrappedError = PlaybackError.downloadError("URLSession error: \(error.localizedDescription)")
                self.logger.error("Creating wrapped error for item \(itemId)")
                self.activeDownloads[itemId] = DownloadState(progress: 0, status: .failed(error.localizedDescription))
                self.downloadContinuations[itemId]?.resume(throwing: wrappedError)
                self.downloadTasks.removeValue(forKey: downloadTask)
                self.downloadContinuations.removeValue(forKey: itemId)
            } else {
                self.logger.debug("Download task \(downloadTask.taskIdentifier) completed successfully")
            }
        }
    }
} 
