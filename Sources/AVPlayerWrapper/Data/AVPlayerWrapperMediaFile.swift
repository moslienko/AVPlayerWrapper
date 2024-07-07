//
//  File.swift
//  
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import Foundation
import UIKit

public class AVPlayerWrapperMediaFile {
    public var fileUrl: URL
    public var title: String?
    public var coverUrl: URL?
    public var coverImage: UIImage?
    
    public init(fileUrl: URL, title: String? = nil, coverUrl: URL? = nil, coverImage: UIImage? = nil) {
        self.fileUrl = fileUrl
        self.title = title
        self.coverUrl = coverUrl
        self.coverImage = coverImage
    }
}
