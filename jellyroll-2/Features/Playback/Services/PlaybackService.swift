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

@MainActor
class PlaybackService: NSObject, ObservableObject {
    static let shared = PlaybackService()
    private let authService = AuthenticationService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "PlaybackService")
    
    @Published private(set) var activeDownloads: [String: DownloadState] = [:] {
        didSet {
            Task { @MainActor in
                self.saveDownloadStates()
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
        super.init()
        loadDownloadStates()
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
    
    private func saveDownloadStates() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.activeDownloads)
            UserDefaults.standard.set(data, forKey: "downloadStates")
            UserDefaults.standard.synchronize()  // Force immediate save
            self.logger.debug("Saved \(self.activeDownloads.count) download states")
            
            // Log the current states for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                self.logger.debug("Saved JSON: \(jsonString)")
            }
            
            for (itemId, state) in self.activeDownloads {
                self.logger.debug("State for \(itemId): status=\(String(describing: state.status)), url=\(state.localURL?.path ?? "nil")")
            }
        } catch {
            self.logger.error("Failed to save download states: \(error.localizedDescription)")
        }
    }
    
    private func loadDownloadStates() {
        guard let data = UserDefaults.standard.data(forKey: "downloadStates") else { 
            self.logger.debug("No saved download states found")
            return 
        }
        
        // Log the raw data for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            self.logger.debug("Loading JSON: \(jsonString)")
        }
        
        do {
            let decoder = JSONDecoder()
            var states = try decoder.decode([String: DownloadState].self, from: data)
            self.logger.debug("Loaded \(states.count) download states")
            
            let fileManager = FileManager.default
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                self.logger.error("Could not access Documents directory")
                return
            }
            let downloadsURL = documentsURL.appendingPathComponent("Downloads", isDirectory: true)
            
            // Process each state
            var newStates: [String: DownloadState] = [:]
            for (itemId, state) in states {
                // Check if the file exists for this state
                let expectedPath = downloadsURL.appendingPathComponent("\(itemId).mp4")
                let fileExists = fileManager.fileExists(atPath: expectedPath.path)
                self.logger.debug("Checking file at \(expectedPath.path): exists=\(fileExists)")
                
                if fileExists {
                    // If the file exists, mark it as downloaded regardless of previous state
                    self.logger.debug("File exists, marking as downloaded")
                    newStates[itemId] = DownloadState(progress: 1.0, status: .downloaded, localURL: expectedPath)
                } else {
                    // If the file doesn't exist, mark as not downloaded
                    self.logger.debug("File does not exist, marking as not downloaded")
                    newStates[itemId] = DownloadState(progress: 0, status: .notDownloaded)
                }
            }
            
            self.logger.debug("Final state count after validation: \(newStates.count)")
            self.activeDownloads = newStates
        } catch {
            self.logger.error("Failed to load download states: \(error.localizedDescription)")
            self.activeDownloads = [:]
        }
    }
    
    func getPlaybackURL(for item: MediaItem) async throws -> URL {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw PlaybackError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let baseURL = URL(string: urlString) else {
            throw PlaybackError.invalidURL
        }
        
        // Construct the video stream URL
        let playbackURL = baseURL
            .appendingPathComponent("Videos")
            .appendingPathComponent(item.id)
            .appendingPathComponent("stream")
        
        var components = URLComponents(url: playbackURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "static", value: "true"),
            URLQueryItem(name: "api_key", value: token.accessToken),
            // Basic audio parameters
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
    
    func updatePlaybackProgress(for item: MediaItem, positionTicks: Int64) async throws {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw PlaybackError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let baseURL = URL(string: urlString) else {
            throw PlaybackError.invalidURL
        }
        
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
        
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            self.logger.error("Failed to get server configuration or token")
            throw PlaybackError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let baseURL = URL(string: urlString) else {
            self.logger.error("Invalid base URL: \(urlString)")
            throw PlaybackError.invalidURL
        }
        
        let downloadURL = baseURL
            .appendingPathComponent("Videos")
            .appendingPathComponent(item.id)
            .appendingPathComponent("stream")
        
        var components = URLComponents(url: downloadURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "static", value: "true"),
            URLQueryItem(name: "api_key", value: token.accessToken),
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "MaxAudioChannels", value: "2"),
            URLQueryItem(name: "AudioSampleRate", value: "44100"),
            URLQueryItem(name: "StartTimeTicks", value: "0")
        ]
        
        guard let finalURL = components.url else {
            self.logger.error("Failed to create final URL from components")
            throw PlaybackError.invalidURL
        }
        
        self.logger.debug("Download URL: \(finalURL.absoluteString)")
        
        var request = URLRequest(url: finalURL)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        // Create downloads directory
        let fileManager = FileManager.default
        let downloadsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Downloads", isDirectory: true)
        
        self.logger.debug("Downloads directory path: \(downloadsURL.path)")
        
        do {
            try fileManager.createDirectory(at: downloadsURL, withIntermediateDirectories: true)
            self.logger.debug("Successfully created/verified Downloads directory")
        } catch {
            self.logger.error("Failed to create Downloads directory: \(error.localizedDescription)")
        }
        
        // Start download task
        self.activeDownloads[item.id] = DownloadState(progress: 0, status: .downloading)
        self.logger.debug("Starting download task for item: \(item.id)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = downloadSession.downloadTask(with: request)
            downloadTasks[task] = item.id
            downloadContinuations[item.id] = continuation
            task.resume()
            self.logger.debug("Download task started with identifier: \(task.taskIdentifier)")
        }
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
    
    func getDownloadedURL(for itemId: String) -> URL? {
        return activeDownloads[itemId]?.localURL
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
                guard let self = self else { return }
                self.logger.error("[Download] Failed to copy temporary file: \(error)")
            }
            return
        }
        
        // Now proceed with async operations using our safely copied file
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.logger.debug("[Download] Starting download completion process")
            
            guard let itemId = self.getItemId(for: downloadTask) else {
                self.logger.error("[Download] Failed to get itemId for task: \(downloadTask.taskIdentifier)")
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
            guard let self = self,
                  let itemId = self.getItemId(for: downloadTask) else { return }
            
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
            guard let self = self else { return }
            
            // Wait for any ongoing processing to complete
            while self.processingTasks.contains(downloadTask.taskIdentifier) {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                self.logger.debug("[Download] Waiting for processing to complete for task \(downloadTask.taskIdentifier)")
            }
            
            if let error = error {
                self.logger.error("Download task \(downloadTask.taskIdentifier) failed with error: \(error.localizedDescription)")
                self.logger.error("URLSession error type: \(type(of: error))")
                self.logger.error("Full error details: \(error)")
                
                guard let itemId = self.getItemId(for: downloadTask) else { return }
                
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