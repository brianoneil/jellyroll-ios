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
    
    @Published private(set) var activeDownloads: [String: DownloadState] = [:]
    private var downloadTasks: [URLSessionDownloadTask: String] = [:]
    private var downloadContinuations: [String: CheckedContinuation<URL, Error>] = [:]
    
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
    }
    
    struct DownloadState {
        var progress: Double
        var status: DownloadStatus
        var localURL: URL?
    }
    
    enum DownloadStatus {
        case notDownloaded
        case downloading
        case downloaded
        case failed(Error)
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
        logger.debug("Starting download for item: \(item.id) - \(item.name)")
        
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
            logger.error("Failed to create final URL from components")
            throw PlaybackError.invalidURL
        }
        
        logger.debug("Download URL: \(finalURL.absoluteString)")
        
        var request = URLRequest(url: finalURL)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(token.accessToken, forHTTPHeaderField: "X-MediaBrowser-Token")
        
        // Create downloads directory
        let fileManager = FileManager.default
        let downloadsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Downloads", isDirectory: true)
        
        logger.debug("Downloads directory path: \(downloadsURL.path)")
        
        do {
            try fileManager.createDirectory(at: downloadsURL, withIntermediateDirectories: true)
            logger.debug("Successfully created/verified Downloads directory")
        } catch {
            logger.error("Failed to create Downloads directory: \(error.localizedDescription)")
        }
        
        // Start download task
        activeDownloads[item.id] = DownloadState(progress: 0, status: .downloading)
        logger.debug("Starting download task for item: \(item.id)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = downloadSession.downloadTask(with: request)
            downloadTasks[task] = item.id
            downloadContinuations[item.id] = continuation
            task.resume()
            logger.debug("Download task started with identifier: \(task.taskIdentifier)")
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
        Task { @MainActor [weak self] in
            guard let self = self,
                  let itemId = self.getItemId(for: downloadTask) else {
                logger.error("Failed to get itemId for download task: \(downloadTask.taskIdentifier)")
                return
            }
            
            logger.debug("Download completed for item: \(itemId)")
            logger.debug("Temporary file location: \(location.path)")
            
            do {
                let fileManager = FileManager.default
                
                // Get the app's Documents directory
                guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    logger.error("Could not access Documents directory")
                    throw PlaybackError.downloadError("Could not access Documents directory")
                }
                
                logger.debug("Documents directory: \(documentsPath.path)")
                
                // Create a unique directory for downloads
                let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
                logger.debug("Downloads path: \(downloadsPath.path)")
                
                // Create the directory if it doesn't exist
                do {
                    try fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true, attributes: nil)
                    logger.debug("Successfully created Downloads directory")
                } catch {
                    logger.error("Failed to create Downloads directory: \(error.localizedDescription)")
                    throw PlaybackError.downloadError("Failed to create Downloads directory: \(error.localizedDescription)")
                }
                
                // Create the destination URL
                let destinationURL = downloadsPath.appendingPathComponent("\(itemId).mp4")
                logger.debug("Destination URL: \(destinationURL.path)")
                
                // If a file already exists at the destination, remove it
                if fileManager.fileExists(atPath: destinationURL.path) {
                    do {
                        try fileManager.removeItem(at: destinationURL)
                        logger.debug("Removed existing file at destination")
                    } catch {
                        logger.error("Failed to remove existing file: \(error.localizedDescription)")
                        throw PlaybackError.downloadError("Failed to remove existing file: \(error.localizedDescription)")
                    }
                }
                
                // Copy the file instead of moving it
                do {
                    try fileManager.copyItem(at: location, to: destinationURL)
                    logger.debug("Successfully copied file to destination")
                } catch {
                    logger.error("Failed to copy file: \(error.localizedDescription)")
                    throw PlaybackError.downloadError("Failed to copy downloaded file: \(error.localizedDescription)")
                }
                
                // Verify the file exists and has content
                guard fileManager.fileExists(atPath: destinationURL.path),
                      let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path),
                      let fileSize = attributes[.size] as? UInt64,
                      fileSize > 0 else {
                    logger.error("File verification failed")
                    throw PlaybackError.downloadError("Downloaded file is empty or missing")
                }
                
                logger.debug("File verification successful. Size: \(fileSize) bytes")
                
                // Update state
                self.activeDownloads[itemId] = DownloadState(progress: 1.0, status: .downloaded, localURL: destinationURL)
                self.downloadContinuations[itemId]?.resume(returning: destinationURL)
                self.downloadTasks.removeValue(forKey: downloadTask)
                self.downloadContinuations.removeValue(forKey: itemId)
                
                logger.debug("Download process completed successfully")
            } catch {
                logger.error("Download error: \(error.localizedDescription)")
                if let error = error as? PlaybackError {
                    self.activeDownloads[itemId] = DownloadState(progress: 0, status: .failed(error))
                    self.downloadContinuations[itemId]?.resume(throwing: error)
                } else {
                    let wrappedError = PlaybackError.downloadError(error.localizedDescription)
                    self.activeDownloads[itemId] = DownloadState(progress: 0, status: .failed(wrappedError))
                    self.downloadContinuations[itemId]?.resume(throwing: wrappedError)
                }
                self.downloadTasks.removeValue(forKey: downloadTask)
                self.downloadContinuations.removeValue(forKey: itemId)
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor [weak self] in
            guard let self = self,
                  let itemId = self.getItemId(for: downloadTask) else { return }
            
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            logger.debug("Download progress for \(itemId): \(Int(progress * 100))% (\(totalBytesWritten)/\(totalBytesExpectedToWrite) bytes)")
            
            if var state = self.activeDownloads[itemId] {
                state.progress = progress
                self.activeDownloads[itemId] = state
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask else { return }
        
        if let error = error {
            logger.error("Download task \(downloadTask.taskIdentifier) failed with error: \(error.localizedDescription)")
            
            Task { @MainActor [weak self] in
                guard let self = self,
                      let itemId = self.getItemId(for: downloadTask) else { return }
                
                self.activeDownloads[itemId] = DownloadState(progress: 0, status: .failed(error))
                self.downloadContinuations[itemId]?.resume(throwing: error)
                self.downloadTasks.removeValue(forKey: downloadTask)
                self.downloadContinuations.removeValue(forKey: itemId)
            }
        } else {
            logger.debug("Download task \(downloadTask.taskIdentifier) completed successfully")
        }
    }
} 