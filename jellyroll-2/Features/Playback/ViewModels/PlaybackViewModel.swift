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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Failed to configure audio session: \(error)")
        }
    }
    
    func play(item: MediaItem) async {
        isLoading = true
        errorMessage = nil
        currentItem = item
        
        do {
            // Check if the item is downloaded
            if let downloadedURL = playbackService.getDownloadedURL(for: item.id) {
                // Play from local file
                let asset = AVAsset(url: downloadedURL)
                let playerItem = AVPlayerItem(asset: asset)
                await MainActor.run {
                    player = AVPlayer(playerItem: playerItem)
                    configureAudioSession()
                    player?.play()
                    isPlaying = true
                }
            } else {
                // Stream from server
                let streamURL = try await playbackService.getPlaybackURL(for: item)
                await MainActor.run {
                    player = AVPlayer(url: streamURL)
                    configureAudioSession()
                    player?.play()
                    isPlaying = true
                }
            }
            
            cleanupStorage.player = player
            
            // Observe playback time
            let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time.seconds
                if let duration = self.player?.currentItem?.duration {
                    self.duration = duration.seconds
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
        cleanupStorage.cleanup()
    }
}

// Separate class to handle nonisolated cleanup
private final class CleanupStorage {
    private let queue = DispatchQueue(label: "com.jellyroll.playback.cleanup")
    private var _player: AVPlayer?
    private var _timeObserver: Any?
    
    var player: AVPlayer? {
        get { queue.sync { _player } }
        set { queue.sync { _player = newValue } }
    }
    
    var timeObserver: Any? {
        get { queue.sync { _timeObserver } }
        set { queue.sync { _timeObserver = newValue } }
    }
    
    func cleanup() {
        queue.sync {
            if let observer = _timeObserver {
                _player?.removeTimeObserver(observer)
            }
            _player?.pause()
            _player = nil
            _timeObserver = nil
        }
    }
} 