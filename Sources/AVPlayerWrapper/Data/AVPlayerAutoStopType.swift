//
//  AVPlayerAutoStopType.swift
//
//
//  Created by Pavel Moslienko on 09.07.2024.
//

import Foundation

/// An enum representing the auto-stop playing types for AVPlayer.
public enum AVPlayerAutoStopType {
    
    /// Auto-stop is disabled.
    case disable
    
    /// Auto-stop after the current track ends.
    case afterTrackEnd
    
    /// Auto-stop after a specified number of seconds.
    case after(_ seconds: TimeInterval)
}
