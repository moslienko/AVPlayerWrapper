//
//  AVSession.swift
//
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import Foundation
import AVFAudio
import AVFoundation

#if os(iOS)
/// A struct representing the AV audio session configuration for iOS.
public struct AVSession {
    
    /// The category of the AV audio session.
    public var category: AVAudioSession.Category
    
    /// The mode of the AV audio session.
    public var mode: AVAudioSession.Mode
    
    /// The options for the AV audio session category.
    public var options: AVAudioSession.CategoryOptions
    
    /// Initializes a new instance of `AVSession`.
    ///
    /// - Parameters:
    ///   - category: The category of the AV audio session.
    ///   - mode: The mode of the AV audio session
    ///   - options: The options for the AV audio session category.
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
#elseif os(macOS)
/// A struct representing the AV audio session configuration for macOS.
public struct AVSession {
    
    public let audioEngine = AVAudioEngine()
    
    public init() {}
}
#endif
