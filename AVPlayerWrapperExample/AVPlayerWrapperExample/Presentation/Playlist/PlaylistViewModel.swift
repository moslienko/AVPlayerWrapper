//
//  PlaylistViewModel.swift
//  AVPlayerWrapperExample
//
//  Created by Pavel Moslienko on 03.07.2024.
//

import AVPlayerWrapper
import Foundation

final class PlaylistViewModel {
    
    let musicPlayer = AVPlayerWrapper()
    var musicUrls: [URL] = []
    
    init() {
        if let url = URL(string: "http://webaudioapi.com/samples/audio-tag/chrono.mp3") {
            musicUrls += [url]
        }
        if let url = URL(string: "https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.mp3") {
            musicUrls += [url]
        }
        if let url = URL(string: "https://www.kozco.com/tech/piano2-CoolEdit.mp3") {
            musicUrls += [url]
        }
    }
}
