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
        logger.debug("[Player] Configuring player with item")
        let player = AVPlayer(playerItem: playerItem)
        
        // Configure for optimal streaming playback
        if #available(iOS 15.0, *) {
            logger.debug("[Player] Setting preferred resolution to 4K")
            playerItem.preferredMaximumResolution = .init(width: 3840, height: 2160)
        }
        
        // Configure player settings for HLS
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        player.automaticallyWaitsToMinimizeStalling = true
        
        // Configure playback settings
        let audioSession = AVAudioSession.sharedInstance()
        do {
            logger.debug("[Player] Configuring audio session")
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("[Player] Audio session configuration failed: \(error)")
        }
        
        self.player = player
        cleanupStorage.player = player
        
        // Add error handling observer
        let statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch item.status {
                case .failed:
                    self.logger.error("[Player] Playback failed: \(String(describing: item.error))")
                    if let error = item.error as NSError? {
                        self.logger.error("[Player] Error domain: \(error.domain), code: \(error.code)")
                        self.logger.error("[Player] Error userInfo: \(error.userInfo)")
                    }
                    self.errorMessage = item.error?.localizedDescription ?? "Playback failed"
                case .readyToPlay:
                    self.logger.debug("[Player] Player item ready to play")
                case .unknown:
                    self.logger.debug("[Player] Player item status unknown")
                @unknown default:
                    self.logger.debug("[Player] Player item status: unknown state")
                }
            }
        }
        cleanupStorage.statusObserver = statusObserver
        
        // Log asset details
        if let asset = playerItem.asset as? AVURLAsset {
            Task {
                if #available(iOS 16.0, *) {
                    do {
                        let duration = try await asset.load(.duration)
                        let tracks = try await asset.load(.tracks)
                        self.logger.debug("[Player] Asset duration: \(duration.seconds)")
                        for track in tracks {
                            let isEnabled = try await track.load(.isEnabled)
                            self.logger.debug("[Player] Track: \(track.mediaType.rawValue), enabled: \(isEnabled)")
                        }
                    } catch {
                        self.logger.error("[Player] Failed to load asset properties: \(error)")
                    }
                } else {
                    // Pre-iOS 16 fallback
                    self.logger.debug("[Player] Asset duration: \(asset.duration.seconds)")
                    for track in asset.tracks {
                        self.logger.debug("[Player] Track: \(track.mediaType.rawValue), enabled: \(track.isEnabled)")
                    }
                }
            }
        }
    }
    
    func play(item: MediaItem) async {
        logger.debug("[Playback] Starting playback for item: \(item.id) - \(item.name)")
        isLoading = true
        errorMessage = nil
        currentItem = item
        
        do {
            // Check if the item is downloaded
            if let downloadedURL = playbackService.getDownloadedURL(for: item.id) {
                logger.debug("[Playback] Playing downloaded file from: \(downloadedURL.path)")
                
                // Verify file exists and is readable
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: downloadedURL.path),
                      fileManager.isReadableFile(atPath: downloadedURL.path) else {
                    logger.error("[Playback] Downloaded file not accessible: \(downloadedURL.path)")
                    throw PlaybackError.downloadError("Downloaded file not accessible")
                }
                
                // Create asset with options for local playback
                logger.debug("[Playback] Creating asset for local playback")
                let asset = AVURLAsset(url: downloadedURL, options: [
                    AVURLAssetPreferPreciseDurationAndTimingKey: true
                ])
                
                // Load essential properties asynchronously
                do {
                    if #available(iOS 16.0, *) {
                        logger.debug("[Playback] Loading asset properties (iOS 16+)")
                        async let playable = try asset.load(.isPlayable)
                        async let duration = try asset.load(.duration)
                        async let transform = try asset.load(.preferredTransform)
                        
                        // Wait for all properties to load
                        let (isPlayable, _, _) = try await (playable, duration, transform)
                        
                        if !isPlayable {
                            logger.error("[Playback] Asset is not playable")
                            throw PlaybackError.downloadError("Asset is not playable")
                        }
                    } else {
                        // Fallback for older iOS versions
                        logger.debug("[Playback] Loading asset properties (pre-iOS 16)")
                        await withCheckedContinuation { continuation in
                            asset.loadValuesAsynchronously(forKeys: ["playable", "duration", "preferredTransform"]) {
                                var error: NSError?
                                let status = asset.statusOfValue(forKey: "playable", error: &error)
                                if status == .failed {
                                    Task { @MainActor in
                                        self.logger.error("[Playback] Asset loading failed: \(String(describing: error))")
                                        self.errorMessage = error?.localizedDescription ?? "Failed to load asset"
                                    }
                                }
                                continuation.resume()
                            }
                        }
                    }
                    
                    logger.debug("[Playback] Creating player item")
                    let playerItem = AVPlayerItem(asset: asset)
                    
                    await MainActor.run {
                        logger.debug("[Playback] Configuring player")
                        configurePlayer(with: playerItem)
                        player?.play()
                        isPlaying = true
                    }
                }
            } else {
                // Stream from server
                logger.debug("[Playback] Streaming from server")
                let streamURL = try await playbackService.getPlaybackURL(for: item)
                logger.debug("[Playback] Got stream URL: \(streamURL.absoluteString)")
                
                let asset = AVURLAsset(url: streamURL)
                logger.debug("[Playback] Created asset for streaming")
                
                // Load essential properties asynchronously
                do {
                    if #available(iOS 16.0, *) {
                        logger.debug("[Playback] Loading streaming asset properties (iOS 16+)")
                        async let playable = try asset.load(.isPlayable)
                        async let duration = try asset.load(.duration)
                        async let transform = try asset.load(.preferredTransform)
                        
                        // Wait for all properties to load
                        let (isPlayable, _, _) = try await (playable, duration, transform)
                        
                        if !isPlayable {
                            logger.error("[Playback] Streaming asset is not playable")
                            throw PlaybackError.serverError("Asset is not playable")
                        }
                    } else {
                        // Fallback for older iOS versions
                        logger.debug("[Playback] Loading streaming asset properties (pre-iOS 16)")
                        await withCheckedContinuation { continuation in
                            asset.loadValuesAsynchronously(forKeys: ["playable", "duration", "preferredTransform"]) {
                                var error: NSError?
                                let status = asset.statusOfValue(forKey: "playable", error: &error)
                                if status == .failed {
                                    Task { @MainActor in
                                        self.logger.error("[Playback] Streaming asset loading failed: \(String(describing: error))")
                                        self.errorMessage = error?.localizedDescription ?? "Failed to load asset"
                                    }
                                }
                                continuation.resume()
                            }
                        }
                    }
                    
                    logger.debug("[Playback] Creating player item for streaming")
                    let playerItem = AVPlayerItem(asset: asset)
                    await MainActor.run {
                        logger.debug("[Playback] Configuring player for streaming")
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
        
        let positionTicks = PlaybackProgressUtility.secondsToTicks(currentTime)
        
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