//
//  ExampleType.swift
//  AVPlayerWrapperExample
//
//  Created by Pavel Moslienko on 06.07.2024.
//

import Foundation

enum ExampleType: CaseIterable {
    case singleLocal, singleUrl, playlistRemote
    
    var title: String {
        switch self {
        case .singleLocal:
            return "Play single local file"
        case .singleUrl:
            return "Play single remote file"
        case .playlistRemote:
            return "Playlist with multiple remote files"
        }
    }
}
