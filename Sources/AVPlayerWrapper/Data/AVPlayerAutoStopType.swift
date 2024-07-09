//
//  AVPlayerAutoStopType.swift
//
//
//  Created by Pavel Moslienko on 09.07.2024.
//

import Foundation

public enum AVPlayerAutoStopType {
    case disable, afterTrackEnd, after(_ seconds: TimeInterval)
}
