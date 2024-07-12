//
//  ExamplesListViewModel.swift
//  AVPlayerWrapperExample
//
//  Created by Pavel Moslienko on 03.07.2024.
//

import AVPlayerWrapper
import Foundation

final class ExamplesListViewModel {
    
    let singleMusicPlayer = AVPlayerWrapper()
    let remoteMusicPlayer = AVPlayerWrapper()
    let examples = ExampleType.allCases
}
