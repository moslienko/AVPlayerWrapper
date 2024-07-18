//
//  AVPlayerAfterAutoStopAction.swift
//
//
//  Created by Pavel Moslienko on 09.07.2024.
//

import Foundation

/// An enum representing the actions to be taken after the auto-stop for AVPlayer.
public enum AVPlayerAfterAutoStopAction {
    
    /// Pause the current track.
    case pauseCurrentTrack
    
    /// Pause and load the next track.
    case pauseAndLoadNextTrack
    
    /// Reset the current track.
    case resetCurrentTrack
    
    /// Stop playback.
    case stop
}
