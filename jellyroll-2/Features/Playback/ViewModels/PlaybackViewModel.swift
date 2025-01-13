import Foundation
import AVKit
import OSLog
import AVFoundation

@MainActor
class PlaybackViewModel: ObservableObject {
    private let playbackService = PlaybackService.shared
    private let logger = Logger(subsystem: "com.jellyroll.app", category: "PlaybackViewModel")
    @Published private(set) var player: AVPlayer?
    private var timeObserver: Any?
    
    @Published var currentItem: MediaItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying = false
    
    // Nonisolated storage for cleanup
    private var cleanupStorage = CleanupStorage()
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
        } catch {
            logger.error("Failed to configure audio session: \(error)")
        }
    }
    
    private func configurePlayer(with playerItem: AVPlayerItem) {
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        cleanupStorage.player = player
    }
    
    func play(item: MediaItem) async {
        isLoading = true
        errorMessage = nil
        currentItem = item
        
        do {
            // Check if the item is downloaded
            if let downloadedURL = playbackService.getDownloadedURL(for: item.id) {
                // Play from local file
                self.logger.debug("Playing downloaded file from: \(downloadedURL.path)")
                
                // Verify file exists and is readable
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: downloadedURL.path),
                      fileManager.isReadableFile(atPath: downloadedURL.path) else {
                    self.logger.error("Downloaded file not accessible: \(downloadedURL.path)")
                    throw PlaybackError.downloadError("Downloaded file not accessible")
                }
                
                // Create asset with options for local playback
                let asset = AVURLAsset(url: downloadedURL, options: [
                    AVURLAssetPreferPreciseDurationAndTimingKey: true
                ])
                
                // Load essential properties asynchronously
                do {
                    if #available(iOS 16.0, *) {
                        async let playable = try asset.load(.isPlayable)
                        async let duration = try asset.load(.duration)
                        async let transform = try asset.load(.preferredTransform)
                        
                        // Wait for all properties to load
                        let (isPlayable, _, _) = try await (playable, duration, transform)
                        
                        if !isPlayable {
                            throw PlaybackError.downloadError("Asset is not playable")
                        }
                    } else {
                        // Fallback for older iOS versions
                        await withCheckedContinuation { continuation in
                            asset.loadValuesAsynchronously(forKeys: ["playable", "duration", "preferredTransform"]) {
                                var error: NSError?
                                let status = asset.statusOfValue(forKey: "playable", error: &error)
                                if status == .failed {
                                    Task { @MainActor in
                                        self.errorMessage = error?.localizedDescription ?? "Failed to load asset"
                                    }
                                }
                                continuation.resume()
                            }
                        }
                    }
                    
                    // Create player item with loaded asset
                    let playerItem = AVPlayerItem(asset: asset)
                    
                    // Configure player on main actor
                    await MainActor.run {
                        // Configure audio session for local playback
                        do {
                            let audioSession = AVAudioSession.sharedInstance()
                            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
                            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                        } catch {
                            logger.error("Failed to configure audio session: \(error)")
                        }
                        
                        // Configure player with more robust settings
                        let player = AVPlayer(playerItem: playerItem)
                        player.allowsExternalPlayback = true
                        player.usesExternalPlaybackWhileExternalScreenIsActive = true
                        player.volume = 1.0
                        player.automaticallyWaitsToMinimizeStalling = true
                        
                        // Add KVO observers for better error handling
                        let statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
                            if item.status == .failed {
                                self?.logger.error("Player item failed: \(String(describing: item.error))")
                                Task { @MainActor [weak self] in
                                    self?.errorMessage = item.error?.localizedDescription ?? "Playback failed"
                                }
                            }
                        }
                        cleanupStorage.statusObserver = statusObserver
                        
                        self.player = player
                        cleanupStorage.player = player
                        player.play()
                        isPlaying = true
                    }
                }
            } else {
                // Stream from server
                let streamURL = try await playbackService.getPlaybackURL(for: item)
                let asset = AVURLAsset(url: streamURL)
                
                // Load essential properties asynchronously
                do {
                    if #available(iOS 16.0, *) {
                        async let playable = try asset.load(.isPlayable)
                        async let duration = try asset.load(.duration)
                        async let transform = try asset.load(.preferredTransform)
                        
                        // Wait for all properties to load
                        let (isPlayable, _, _) = try await (playable, duration, transform)
                        
                        if !isPlayable {
                            throw PlaybackError.serverError("Asset is not playable")
                        }
                    } else {
                        // Fallback for older iOS versions
                        await withCheckedContinuation { continuation in
                            asset.loadValuesAsynchronously(forKeys: ["playable", "duration", "preferredTransform"]) {
                                var error: NSError?
                                let status = asset.statusOfValue(forKey: "playable", error: &error)
                                if status == .failed {
                                    Task { @MainActor in
                                        self.errorMessage = error?.localizedDescription ?? "Failed to load asset"
                                    }
                                }
                                continuation.resume()
                            }
                        }
                    }
                    
                    let playerItem = AVPlayerItem(asset: asset)
                    await MainActor.run {
                        configureAudioSession()
                        configurePlayer(with: playerItem)
                        player?.play()
                        isPlaying = true
                    }
                }
            }
            
            // Observe playback time
            let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                Task { @MainActor in
                    self.currentTime = time.seconds
                    if let duration = self.player?.currentItem?.duration.seconds {
                        self.duration = duration
                    }
                }
            }
            cleanupStorage.timeObserver = timeObserver
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                logger.error("Playback error: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    func seek(to time: Double) async {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1)
        await player?.seek(to: cmTime)
        await updateProgress()
    }
    
    private func setupTimeObserver() {
        // Remove existing observer if any
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
            cleanupStorage.timeObserver = nil
        }
        
        // Create new time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let observer = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentTime = time.seconds
                self.duration = self.player?.currentItem?.duration.seconds ?? 0
                await self.updateProgress()
            }
        }
        timeObserver = observer
        cleanupStorage.timeObserver = observer
    }
    
    private func updateProgress() async {
        guard let item = currentItem,
              let player = player,
              let currentItem = player.currentItem,
              currentItem.status == .readyToPlay else {
            return
        }
        
        let position = currentTime
        let positionTicks = Int64(position * 10_000_000)
        
        do {
            try await playbackService.updatePlaybackProgress(for: item, positionTicks: positionTicks)
        } catch {
            logger.error("Failed to update progress: \(error)")
        }
    }
    
    func cleanup() async {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
            cleanupStorage.timeObserver = nil
        }
        player?.pause()
        player = nil
        cleanupStorage.player = nil
        currentItem = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    
    deinit {
        // CleanupStorage handles cleanup in its own deinit
    }
}

// Separate class to handle nonisolated cleanup
private final class CleanupStorage {
    weak var player: AVPlayer?
    var timeObserver: Any?
    var statusObserver: NSKeyValueObservation?
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        statusObserver?.invalidate()
        player = nil
    }
} 