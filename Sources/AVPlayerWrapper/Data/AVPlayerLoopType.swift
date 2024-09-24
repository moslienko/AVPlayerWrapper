//
//  AVPlayerLoopType.swift
//
//
//  Created by Pavel Moslienko on 24.09.2024.
//

import Foundation

/// An enum representing the looping of file playback.
public enum AVPlayerLoopType {
    
    /// Playing without looping.
    case disable
    
    /// Loop playback indefinitely.
    case infinitely
    
    /// Cycle for a certain number of times.
    case times(_: Int)
}
