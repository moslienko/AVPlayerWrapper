//
//  File.swift
//
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import Foundation

#if os(iOS)
import UIKit
public typealias MultiPlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias MultiPlatformImage = NSImage
#endif

/// A class representing a media file for AVPlayer.
public class AVPlayerWrapperMediaFile {
    
    /// The URL of the media file.
    public var fileUrl: URL
    
    /// The title of the media file.
    public var title: String?
    
    /// The URL of the cover image.
    public var coverUrl: URL?
    
    /// The cover image.
    public var coverImage: MultiPlatformImage?
    
    /// Looping of file playback.
    public var loopType: AVPlayerLoopType
    
    /// Initializes a new instance of `AVPlayerWrapperMediaFile`.
    ///
    /// - Parameters:
    ///   - fileUrl: The URL of the media file.
    ///   - title: The title of the media file.
    ///   - coverUrl: The URL of the cover image.
    ///   - coverImage: The cover image.
    ///   - loopType: Looping of file playback.
    public init(fileUrl: URL, title: String? = nil, coverUrl: URL? = nil, coverImage: MultiPlatformImage? = nil, loopType: AVPlayerLoopType = .disable) {
        self.fileUrl = fileUrl
        self.title = title
        self.coverUrl = coverUrl
        self.coverImage = coverImage
        self.loopType = loopType
    }
}
