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
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "DownloadStatePersistence")
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
    private let logger = Logger(subsystem: "com.jammplayer.app", category: "PlaybackService")
    private let statePersistence: DownloadStatePersistable
    
    @Published private(set) var activeDownloads: [String: DownloadState] = [:] {
        didSet {
            Task { @MainActor in
                do {
                    try self.statePersistence.saveStates(self.activeDownloads)
                    logger.debug("[Download] Saved \(self.activeDownloads.count) download states")
                    logger.debug("[Download] Active states: \(self.activeDownloads.keys.joined(separator: ", "))")
                } catch {
                    self.logger.error("Failed to save download states: \(error.localizedDescription)")
                }
            }
        }
    }
    private var downloadTasks: [URLSessionDownloadTask: String] = [:] {
        didSet {
            self.logger.debug("[Download] Download tasks updated - Count: \(self.downloadTasks.count)")
            self.logger.debug("[Download] Task mappings: \(self.downloadTasks.map { "Task \($0.key.taskIdentifier): \($0.value)" }.joined(separator: ", "))")
        }
    }
    private var downloadContinuations: [String: CheckedContinuation<URL, Error>] = [:]
    private var processingTasks: Set<Int> = []
    
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.jammplayer.app.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return URLSession(configuration: config, delegate: self, delegateQueue: queue)
    }()
    
    private var currentPlaySessionId: String?
    
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
        var itemName: String
        
        enum CodingKeys: String, CodingKey {
            case progress
            case status
            case localURL
            case itemName
        }
        
        init(progress: Double, status: DownloadStatus, localURL: URL? = nil, itemName: String) {
            self.progress = progress
            self.status = status
            self.localURL = localURL
            self.itemName = itemName
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            progress = try container.decode(Double.self, forKey: .progress)
            status = try container.decode(DownloadStatus.self, forKey: .status)
            itemName = try container.decode(String.self, forKey: .itemName)
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
            try container.encode(itemName, forKey: .itemName)
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
    
    private func generatePlaySessionId() -> String {
        let sessionId = UUID().uuidString
        currentPlaySessionId = sessionId
        return sessionId
    }

    /// Opens a playback session with the Jellyfin server
    func startPlaybackSession(for item: MediaItem) async throws {
        let (baseURL, token) = try getAuthenticatedBaseURL()
        let playSessionId = generatePlaySessionId()
        
        let sessionURL = baseURL
            .appendingPathComponent("Sessions")
            .appendingPathComponent("Playing")
        
        var request = URLRequest(url: sessionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        let sessionData: [String: Any] = [
            "ItemId": item.id,
            "PlayMethod": "DirectStream",
            "MediaSourceId": item.id,
            "CanSeek": true,
            "PlaySessionId": playSessionId,
            "AudioStreamIndex": 1,
            "SubtitleStreamIndex": -1,
            "IsPaused": false,
            "IsMuted": false,
            "PositionTicks": 0,
            "VolumeLevel": 100,
            "MaxStreamingBitrate": 140000000,
            "AspectRatio": "16x9",
            "EventName": "timeupdate"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: sessionData)
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaybackError.serverError("Invalid response")
            }
            
            // Accept both 200 and 204 as valid responses
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                throw PlaybackError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
        } catch {
            logger.error("Error starting playback session: \(error.localizedDescription)")
            throw PlaybackError.networkError(error)
        }
    }
    
    /// Helper method to construct media stream URLs with proper authentication and parameters
    private func constructMediaStreamURL(for itemId: String, token: AuthenticationToken, baseURL: URL) throws -> URL {
        self.logger.debug("[Stream URL] Constructing stream URL for item: \(itemId)")
        
        let streamURL = baseURL
            .appendingPathComponent("Videos")
            .appendingPathComponent(itemId)
            .appendingPathComponent("master.m3u8")
        
        self.logger.debug("[Stream URL] Base stream URL: \(streamURL.absoluteString)")
        
        var components = URLComponents(url: streamURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: token.accessToken),
            URLQueryItem(name: "MediaSourceId", value: itemId),
            URLQueryItem(name: "PlaySessionId", value: currentPlaySessionId),
            URLQueryItem(name: "VideoCodec", value: "h264"),
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "TranscodingMaxAudioChannels", value: "2"),
            URLQueryItem(name: "RequireAvc", value: "true"),
            URLQueryItem(name: "TranscodingContainer", value: "ts"),
            URLQueryItem(name: "SegmentContainer", value: "ts"),
            URLQueryItem(name: "MinSegments", value: "2"),
            URLQueryItem(name: "ManifestSubtitles", value: "vtt"),
            URLQueryItem(name: "h264-profile", value: "high,main,baseline,constrained-baseline"),
            URLQueryItem(name: "h264-level", value: "51"),
            URLQueryItem(name: "TranscodingProtocol", value: "hls"),
            URLQueryItem(name: "EnableDirectStream", value: "false"),
            URLQueryItem(name: "EnableDirectPlay", value: "false"),
            URLQueryItem(name: "SubtitleMethod", value: "Hls"),
            URLQueryItem(name: "MaxStreamingBitrate", value: "140000000")
        ]
        
        guard let finalURL = components.url else {
            self.logger.error("[Stream URL] Failed to construct URL")
            throw PlaybackError.invalidURL
        }
        
        self.logger.debug("[Stream URL] Final URL: \(finalURL.absoluteString)")
        return finalURL
    }

    /// Helper method to get authenticated server base URL
    private func getAuthenticatedBaseURL() throws -> (URL, AuthenticationToken) {
        guard let token = try? authService.getCurrentToken() else {
            throw PlaybackError.invalidToken
        }
        
        guard let config = try? authService.getServerConfiguration() else {
            throw PlaybackError.invalidURL
        }
        
        return (config.serverURL, token)
    }

    func getPlaybackURL(for item: MediaItem) async throws -> URL {
        self.logger.debug("[Playback] Getting playback URL for item: \(item.id) - \(item.name)")
        let (baseURL, token) = try getAuthenticatedBaseURL()
        self.logger.debug("[Playback] Using base URL: \(baseURL.absoluteString)")
        return try constructMediaStreamURL(for: item.id, token: token, baseURL: baseURL)
    }
    
    func updatePlaybackProgress(for item: MediaItem, positionTicks: Int64, isPaused: Bool = false) async throws {
        let (baseURL, token) = try getAuthenticatedBaseURL()
        
        // Construct the playback progress URL
        let progressURL = baseURL
            .appendingPathComponent("Sessions")
            .appendingPathComponent("Playing")
            .appendingPathComponent("Progress")
        
        var request = URLRequest(url: progressURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        let progressData: [String: Any] = [
            "ItemId": item.id,
            "MediaSourceId": item.id,
            "PositionTicks": positionTicks,
            "IsPaused": isPaused,
            "IsMuted": false,
            "PlaySessionId": currentPlaySessionId ?? UUID().uuidString,
            "AudioStreamIndex": 1,
            "SubtitleStreamIndex": -1,
            "VolumeLevel": 100,
            "PlayMethod": "DirectStream",
            "RepeatMode": "RepeatNone",
            "MaxStreamingBitrate": 140000000,
            "AspectRatio": "16x9",
            "EventName": isPaused ? "pause" : "timeupdate"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: progressData)
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaybackError.serverError("Invalid response")
            }
            
            // Accept both 200 and 204 as valid responses
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                self.logger.error("Progress update failed with status code: \(httpResponse.statusCode)")
                throw PlaybackError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
            
            // Progress update successful, no need to log
        } catch {
            logger.error("Error updating playback progress: \(error.localizedDescription)")
            throw PlaybackError.networkError(error)
        }
    }
    
    func downloadMovie(item: MediaItem) async throws -> URL {
        self.logger.debug("Starting download for item: \(item.id) - \(item.name)")
        
        // Check if already downloading or downloaded
        if let existingState = activeDownloads[item.id] {
            switch existingState.status {
            case .downloaded:
                if let localURL = existingState.localURL,
                   FileManager.default.fileExists(atPath: localURL.path) {
                    return localURL
                }
                // If file doesn't exist, remove state and continue with download
                activeDownloads.removeValue(forKey: item.id)
            case .downloading:
                throw PlaybackError.downloadError("Download already in progress")
            case .failed:
                // Remove failed state and try again
                activeDownloads.removeValue(forKey: item.id)
            case .notDownloaded:
                break
            }
        }
        
        let (baseURL, token) = try getAuthenticatedBaseURL()
        
        // Instead of using HLS stream, construct a direct video download URL
        let downloadURL = baseURL
            .appendingPathComponent("Videos")
            .appendingPathComponent(item.id)
            .appendingPathComponent("stream.mp4")
        
        var components = URLComponents(url: downloadURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: token.accessToken),
            URLQueryItem(name: "MediaSourceId", value: item.id),
            URLQueryItem(name: "VideoCodec", value: "h264"),
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "TranscodingMaxAudioChannels", value: "2"),
            URLQueryItem(name: "RequireAvc", value: "true"),
            URLQueryItem(name: "Container", value: "mp4"),
            URLQueryItem(name: "Static", value: "true")
        ]
        
        guard let finalURL = components.url else {
            self.logger.error("[Download] Failed to construct download URL")
            throw PlaybackError.invalidURL
        }
        
        self.logger.debug("[Download] Using direct download URL: \(finalURL.absoluteString)")
        
        return try await withCheckedThrowingContinuation { continuation in
            self.logger.debug("[Download] Creating download task")
            
            let task = downloadSession.downloadTask(with: finalURL)
            downloadTasks[task] = item.id
            downloadContinuations[item.id] = continuation
            
            // Initialize download state with item name
            activeDownloads[item.id] = DownloadState(
                progress: 0,
                status: .downloading,
                itemName: item.name
            )
            
            self.logger.debug("[Download] Starting download task for item: \(item.id)")
            task.resume()
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
        if let taskEntry = self.downloadTasks.first(where: { $0.value == itemId }) {
            let task = taskEntry.key
            task.cancel()
            
            // Only remove the task mapping after we're sure the cancellation is complete
            Task { @MainActor in
                // Wait a short time to ensure the cancellation is processed
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                self.downloadTasks.removeValue(forKey: task)
                self.logger.debug("[Download] Removed task mapping for cancelled download: \(itemId)")
            }
        }
        
        // Create a temporary URL for cancellation
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let tempURL = documentsPath.appendingPathComponent("cancelled")
            // Resume with a dummy URL to complete the async operation without error
            self.downloadContinuations[itemId]?.resume(returning: tempURL)
        }
        self.downloadContinuations.removeValue(forKey: itemId)
        
        // Remove the download state completely
        self.activeDownloads.removeValue(forKey: itemId)
        
        // Clean up any processing tasks
        self.processingTasks.removeAll()
        
        self.logger.debug("Download cancelled for item: \(itemId)")
    }
    
    private func getItemId(for task: URLSessionDownloadTask) -> String? {
        let itemId = self.downloadTasks[task]
        if itemId == nil {
            self.logger.error("[Download] Failed to find itemId for task: \(task.taskIdentifier)")
        }
        return itemId
    }

    /// Stops the current playback session
    func stopPlaybackSession(for item: MediaItem, positionTicks: Int64) async throws {
        let (baseURL, token) = try getAuthenticatedBaseURL()
        
        let sessionURL = baseURL
            .appendingPathComponent("Sessions")
            .appendingPathComponent("Playing")
            .appendingPathComponent("Stopped")
        
        var request = URLRequest(url: sessionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        let sessionData: [String: Any] = [
            "ItemId": item.id,
            "MediaSourceId": item.id,
            "PositionTicks": positionTicks,
            "PlaySessionId": currentPlaySessionId ?? UUID().uuidString,
            "IsPaused": false,
            "IsMuted": false,
            "VolumeLevel": 100,
            "MaxStreamingBitrate": 140000000,
            "AspectRatio": "16x9"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: sessionData)
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaybackError.serverError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    logger.error("Server error: \(errorText)")
                }
                throw PlaybackError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
            
            // Clear the session ID after successful stop
            currentPlaySessionId = nil
            
        } catch {
            logger.error("Error stopping playback session: \(error)")
            throw PlaybackError.networkError(error)
        }
    }

    /// Fetches child items (seasons or episodes) for a given parent item
    func getChildren(parentId: String, filter: [String]) async throws -> [MediaItem] {
        let (baseURL, token) = try getAuthenticatedBaseURL()
        
        let itemsURL = baseURL
            .appendingPathComponent("Users")
            .appendingPathComponent(token.user.id)
            .appendingPathComponent("Items")
        
        var components = URLComponents(url: itemsURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "ParentId", value: parentId),
            URLQueryItem(name: "IncludeItemTypes", value: filter.joined(separator: ",")),
            URLQueryItem(name: "Fields", value: "Overview,Genres,Tags,ProductionYear,PremiereDate,RunTimeTicks,PlaybackPositionTicks,UserData,People"),
            URLQueryItem(name: "SortBy", value: "SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaybackError.serverError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    logger.error("Server error response: \(errorText)")
                }
                throw PlaybackError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let itemsResponse = try MediaItemResponse.decode(from: data, using: decoder)
            logger.debug("Successfully decoded \(itemsResponse.items.count) items")
            return itemsResponse.items
        } catch let error as DecodingError {
            logger.error("Decoding error: \(error)")
            throw PlaybackError.serverError("Failed to decode response: \(error.localizedDescription)")
        } catch {
            logger.error("Network error details: \(error.localizedDescription)")
            throw PlaybackError.networkError(error)
        }
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
                self.activeDownloads[itemId] = DownloadState(
                    progress: 1.0,
                    status: .downloaded,
                    localURL: destinationURL,
                    itemName: self.activeDownloads[itemId]?.itemName ?? "Unknown Movie"
                )
                self.downloadContinuations[itemId]?.resume(returning: destinationURL)
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
                    self.activeDownloads[itemId] = DownloadState(
                        progress: 0,
                        status: .failed(errorMessage),
                        itemName: self.activeDownloads[itemId]?.itemName ?? "Unknown Movie"
                    )
                    self.downloadContinuations[itemId]?.resume(throwing: playbackError)
                } else {
                    self.logger.error("[Download] System error: \(error)")
                    let errorMessage = error.localizedDescription
                    self.activeDownloads[itemId] = DownloadState(
                        progress: 0,
                        status: .failed(errorMessage),
                        itemName: self.activeDownloads[itemId]?.itemName ?? "Unknown Movie"
                    )
                    self.downloadContinuations[itemId]?.resume(throwing: PlaybackError.downloadError(errorMessage))
                }
                self.downloadContinuations.removeValue(forKey: itemId)
            }
            
            self.processingTasks.remove(downloadTask.taskIdentifier)
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let itemId = self.getItemId(for: downloadTask) else {
                self.logger.error("[Download Progress] Could not find itemId for task: \(downloadTask.taskIdentifier)")
                return
            }
            
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            
            if var state = self.activeDownloads[itemId] {
                state.progress = progress
                self.activeDownloads[itemId] = state
            } else {
                self.logger.error("[Download State] No active download state found for \(itemId)")
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
            }
            
            guard let itemId = self.getItemId(for: downloadTask) else {
                self.logger.error("[Download Complete] Could not find itemId for task: \(downloadTask.taskIdentifier)")
                return
            }
            
            if let error = error {
                // Check if this was a cancellation
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    self.logger.debug("[Download] Cancelled by user: \(itemId)")
                    self.downloadTasks.removeValue(forKey: downloadTask)
                    self.downloadContinuations.removeValue(forKey: itemId)
                    return
                }
                
                // Handle other errors
                self.logger.error("[Download] Error for \(itemId): \(error.localizedDescription)")
                
                let wrappedError = PlaybackError.downloadError("URLSession error: \(error.localizedDescription)")
                self.activeDownloads[itemId] = DownloadState(
                    progress: 0,
                    status: .failed(error.localizedDescription),
                    itemName: self.activeDownloads[itemId]?.itemName ?? "Unknown Movie"
                )
                self.downloadContinuations[itemId]?.resume(throwing: wrappedError)
                self.downloadTasks.removeValue(forKey: downloadTask)
                self.downloadContinuations.removeValue(forKey: itemId)
            } else {
                self.logger.debug("[Download] Completed successfully: \(itemId)")
            }
            
            self.downloadTasks.removeValue(forKey: downloadTask)
        }
    }
} 
