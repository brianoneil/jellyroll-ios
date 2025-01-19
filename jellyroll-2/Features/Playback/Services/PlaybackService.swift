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
    @Published private(set) var offlineItems: [String: OfflineMediaItem] = [:] {
        didSet {
            Task { @MainActor in
                self.saveOfflineItems()
            }
        }
    }
    
    // Make downloadTasks nonisolated by using an actor
    private actor DownloadTasksStore {
        var tasks: [URLSessionDownloadTask: String] = [:]
        
        func getItemId(for task: URLSessionDownloadTask) -> String? {
            return tasks[task]
        }
        
        func setTask(_ task: URLSessionDownloadTask, for itemId: String) {
            tasks[task] = itemId
        }
        
        func removeTask(_ task: URLSessionDownloadTask) {
            tasks.removeValue(forKey: task)
        }
        
        func getTask(for itemId: String) -> URLSessionDownloadTask? {
            return tasks.first(where: { $0.value == itemId })?.key
        }
    }
    
    private let downloadTasksStore = DownloadTasksStore()
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
        if let data = UserDefaults.standard.data(forKey: "downloadStates"),
           let states = try? JSONDecoder().decode([String: DownloadState].self, from: data) {
            self.activeDownloads = states
        }
        
        if let data = UserDefaults.standard.data(forKey: "offlineItems"),
           let items = try? JSONDecoder().decode([String: OfflineMediaItem].self, from: data) {
            self.offlineItems = items
        }
    }
    
    private func saveOfflineItems() {
        if let data = try? JSONEncoder().encode(offlineItems) {
            UserDefaults.standard.set(data, forKey: "offlineItems")
        }
    }
    
    func storeOfflineMetadata(for mediaItem: MediaItem, at localURL: URL) {
        let offlineItem = OfflineMediaItem(from: mediaItem, localURL: localURL)
        offlineItems[mediaItem.id] = offlineItem
    }
    
    func getOfflineItem(id: String) -> OfflineMediaItem? {
        return offlineItems[id]
    }
    
    func deleteOfflineMetadata(id: String) {
        offlineItems.removeValue(forKey: id)
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
        
        // Get downloads directory
        let downloadsURL = try getDownloadsDirectory()
        self.logger.debug("Downloads directory path: \(downloadsURL.path)")
        
        // Start download task
        self.activeDownloads[item.id] = DownloadState(progress: 0, status: .downloading)
        self.logger.debug("Starting download task for item: \(item.id)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = downloadSession.downloadTask(with: request)
            Task {
                await downloadTasksStore.setTask(task, for: item.id)
            }
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
        
        Task {
            // Find and cancel the download task
            if let task = await downloadTasksStore.getTask(for: itemId) {
                task.cancel()
                await downloadTasksStore.removeTask(task)
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
    }
    
    // Add fetchMediaItem method
    private func fetchMediaItem(id: String) async throws -> MediaItem {
        guard let config = try? authService.getServerConfiguration(),
              let token = try? authService.getCurrentToken() else {
            throw PlaybackError.invalidToken
        }
        
        let urlString = config.baseURLString.trimmingCharacters(in: .whitespaces)
        guard let baseURL = URL(string: urlString) else {
            throw PlaybackError.invalidURL
        }
        
        let itemURL = baseURL
            .appendingPathComponent("Users")
            .appendingPathComponent(token.user.id)
            .appendingPathComponent("Items")
            .appendingPathComponent(id)
        
        var request = URLRequest(url: itemURL)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(MediaItem.self, from: data)
    }
}

// MARK: - URLSessionDownloadDelegate
extension PlaybackService: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task {
            guard let itemId = await downloadTasksStore.getItemId(for: downloadTask) else {
                logger.error("No item ID found for download task")
                return
            }
            
            do {
                let fileManager = FileManager.default
                guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    throw PlaybackError.downloadError("Could not access Documents directory")
                }
                
                let downloadsURL = documentsURL.appendingPathComponent("Downloads", isDirectory: true)
                try fileManager.createDirectory(at: downloadsURL, withIntermediateDirectories: true)
                
                let destinationURL = downloadsURL.appendingPathComponent("\(itemId).mp4")
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                try fileManager.moveItem(at: location, to: destinationURL)
                
                // Use Task to switch to the main actor for state updates
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    // Update download state
                    self.activeDownloads[itemId] = DownloadState(progress: 1.0, status: .downloaded, localURL: destinationURL)
                    
                    // Store metadata if available
                    Task {
                        do {
                            let mediaItem = try await self.fetchMediaItem(id: itemId)
                            self.storeOfflineMetadata(for: mediaItem, at: destinationURL)
                        } catch {
                            self.logger.error("Failed to fetch metadata: \(error.localizedDescription)")
                        }
                        
                        if let continuation = self.downloadContinuations.removeValue(forKey: itemId) {
                            continuation.resume(returning: destinationURL)
                        }
                    }
                }
            } catch {
                logger.error("Download completion error: \(error.localizedDescription)")
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.activeDownloads[itemId] = DownloadState(progress: 0, status: .failed(error.localizedDescription))
                    if let continuation = self.downloadContinuations.removeValue(forKey: itemId) {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Clean up the task
            await downloadTasksStore.removeTask(downloadTask)
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task {
            guard let itemId = await downloadTasksStore.getItemId(for: downloadTask) else { return }
            
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.logger.debug("Download progress for \(itemId): \(Int(progress * 100))% (\(totalBytesWritten)/\(totalBytesExpectedToWrite) bytes)")
                
                if var state = self.activeDownloads[itemId] {
                    state.progress = progress
                    self.activeDownloads[itemId] = state
                }
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask else { return }
        
        Task {
            guard let itemId = await downloadTasksStore.getItemId(for: downloadTask) else { return }
            
            // Wait for any ongoing processing to complete
            while await MainActor.run { self.processingTasks.contains(downloadTask.taskIdentifier) } {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                await MainActor.run { [weak self] in
                    self?.logger.debug("[Download] Waiting for processing to complete for task \(downloadTask.taskIdentifier)")
                }
            }
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.debug("Download task \(downloadTask.taskIdentifier) ended with error: \(error.localizedDescription)")
                    
                    // Check if this was a cancellation
                    let nsError = error as NSError
                    if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                        self.logger.debug("Download was cancelled by user")
                        // Don't set any error state for cancellation
                        Task {
                            await self.downloadTasksStore.removeTask(downloadTask)
                        }
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
                } else {
                    self.logger.debug("Download task \(downloadTask.taskIdentifier) completed successfully")
                }
                
                Task {
                    await self.downloadTasksStore.removeTask(downloadTask)
                }
                self.downloadContinuations.removeValue(forKey: itemId)
            }
        }
    }
} 
