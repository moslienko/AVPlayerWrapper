//
//  PlaylistViewModel.swift
//  AVPlayerWrapperExample
//
//  Created by Pavel Moslienko on 03.07.2024.
//

import AVPlayerWrapper
import Foundation

final class PlaylistViewModel {
    
    let musicPlayer = AVPlayerWrapper.shared
    var musicFiles: [AVPlayerWrapperMediaFile] = []
    
    init() {
        if let url = URL(string: "http://webaudioapi.com/samples/audio-tag/chrono.mp3"),
           let coverURL = URL(string: "https://developer.apple.com/wwdc24/images/motion/axiju/endframe-small_2x.jpg")
        {
            musicFiles += [AVPlayerWrapperMediaFile(fileUrl: url, title: "Chrono", coverUrl: coverURL)]
        }
        if let url = URL(string: "https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.mp3"),
           let coverURL = URL(string: "https://developer.apple.com/wwdc24/images/motion/axiju/endframe-small_2x.jpg") {
            musicFiles += [AVPlayerWrapperMediaFile(fileUrl: url, title: "Sample", coverUrl: coverURL)]
        }
        if let url = URL(string: "https://www.kozco.com/tech/piano2-CoolEdit.mp3") {
            musicFiles += [AVPlayerWrapperMediaFile(fileUrl: url, title: "Piano")]
        }
    }
}
