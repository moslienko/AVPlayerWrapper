//
//  AVPlayerOptions.swift
//
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import Foundation

/// A struct representing the options for configuring the AVPlayer.
public struct AVPlayerOptions {
    
    /// Indicates whether the now playing info should be displayed.
    public var isDisplayNowPlaying: Bool
    
    /// The action to be taken after the auto-stop.
    public var actionAfterAutoStopped: AVPlayerAfterAutoStopAction
    
    /// The AV audio session configuration.
    public var session: AVSession
    
    /// Initializes a new instance of `AVPlayerOptions`.
    ///
    /// - Parameters:
    ///   - isDisplayNowPlaying: Indicates whether the now playing info should be displayed.
    ///   - actionAfterAutoStopped: The action to be taken after the auto-stop.
    ///   - session: The AV audio session configuration.
    public init(
        isDisplayNowPlaying: Bool = false,
        actionAfterAutoStopped: AVPlayerAfterAutoStopAction = .pauseCurrentTrack,
        session: AVSession = AVSession()
    ) {
        self.isDisplayNowPlaying = isDisplayNowPlaying
        self.actionAfterAutoStopped = actionAfterAutoStopped
        self.session = session
    }
}
