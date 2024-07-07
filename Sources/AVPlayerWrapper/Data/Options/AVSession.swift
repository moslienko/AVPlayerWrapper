//
//  AVSession.swift
//  
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import Foundation
import AVFAudio

public struct AVSession {
    public var category: AVAudioSession.Category
    public var mode: AVAudioSession.Mode
    public var options: AVAudioSession.CategoryOptions
    
    public init(
        category: AVAudioSession.Category = .playback,
        mode: AVAudioSession.Mode = .default,
        options: AVAudioSession.CategoryOptions = []
    ) {
        self.category = category
        self.mode = mode
        self.options = options
    }
}
