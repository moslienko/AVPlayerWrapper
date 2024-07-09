//
//  AVPlayerOptions.swift
//
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import Foundation

public struct AVPlayerOptions {
    public var isDisplayNowPlaying: Bool
    public var actionAfterAutoStopped: AVPlayerAfterAutoStopAction
    public var session: AVSession
    
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
