//
//  AVAssetTime.swift
//  
//
//  Created by Pavel Moslienko on 09.07.2024.
//

import AVFoundation
import Foundation

/// A struct representing the current time and duration of an AV asset.
public struct AVAssetTime {
    
    /// The current playback time of the AV asset.
    public var currentTime: CMTime
    
    /// The duration of the AV asset.
    public var duration: CMTime
    
    /// Initializes a new instance of `AVAssetTime`.
    ///
    /// - Parameters:
    ///   - currentTime: The current playback time.
    ///   - duration: The duration of the asset.
    public init(currentTime: CMTime, duration: CMTime) {
        self.currentTime = currentTime
        self.duration = duration
    }
}
