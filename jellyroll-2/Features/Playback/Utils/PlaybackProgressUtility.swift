import Foundation

/// Utility for handling playback progress calculations throughout the app
enum PlaybackProgressUtility {
    /// Convert ticks to seconds
    /// - Parameter ticks: The time in ticks (1 tick = 10,000,000th of a second)
    /// - Returns: Time in seconds
    static func ticksToSeconds(_ ticks: Int64) -> Double {
        return Double(ticks) / 10_000_000
    }
    
    /// Convert seconds to ticks
    /// - Parameter seconds: Time in seconds
    /// - Returns: Time in ticks
    static func secondsToTicks(_ seconds: Double) -> Int64 {
        return Int64(seconds * 10_000_000)
    }
    
    /// Calculate playback progress as a percentage
    /// - Parameters:
    ///   - positionTicks: Current playback position in ticks
    ///   - totalTicks: Total duration in ticks
    /// - Returns: Progress as a percentage between 0 and 1, or nil if inputs are invalid
    static func calculateProgress(positionTicks: Int64?, totalTicks: Int64?) -> Double? {
        guard let position = positionTicks,
              let total = totalTicks,
              total > 0 else { return nil }
        return Double(position) / Double(total)
    }
    
    /// Format remaining time in a consistent way across the app
    /// - Parameters:
    ///   - positionTicks: Current playback position in ticks
    ///   - totalTicks: Total duration in ticks
    /// - Returns: Formatted string showing remaining time, or nil if inputs are invalid
    static func formatRemainingTime(positionTicks: Int64?, totalTicks: Int64?) -> String? {
        guard let position = positionTicks,
              let total = totalTicks,
              total > 0 else { return nil }
        
        let remainingTicks = total - position
        let remainingSeconds = ticksToSeconds(remainingTicks)
        let hours = Int(remainingSeconds) / 3600
        let minutes = (Int(remainingSeconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
    
    /// Format duration in minutes
    /// - Parameter ticks: Duration in ticks
    /// - Returns: Formatted string showing duration in minutes, or nil if input is invalid
    static func formatDuration(ticks: Int64?) -> String? {
        guard let ticks = ticks else { return nil }
        let seconds = ticksToSeconds(ticks)
        let minutes = Int(seconds / 60)
        return "\(minutes)min"
    }
} 