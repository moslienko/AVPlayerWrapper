//
//  AVPlayerWrapper.swift
//
//
//  Created by Pavel Moslienko on 03.07.2024.
//

import AppViewUtilits
import AVFoundation
import Foundation
import MediaPlayer
import UIKit

public protocol AVPlayerWrapperDelegate: AnyObject {
    func didStartPlaying()
    func didPause()
    func didStop()
    func didFinishPlaying()
    func didUpdateTime(currentTime: CMTime, duration: CMTime)
    func didSwitchToTrack(index: Int)
}

public class AVPlayerWrapper: NSObject {
    
    // MARK: - Private variables
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var currentTrackIndex = 0
    private var timeObserverToken: Any?
    
    // MARK: - Public variables
    public var playlist: [URL] = []
    
    public var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    // MARK: - Callbacks
    public weak var delegate: AVPlayerWrapperDelegate?
    
    // MARK: - Init
    override public init() {
        super.init()
    }
    
    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
    }
}

// MARK: - Public methods
public extension AVPlayerWrapper {
    
    public func playTrack(at index: Int) {
        guard index < playlist.count else {
            return
        }
        currentTrackIndex = index
        loadTrack(at: index)
        player?.play()
        delegate?.didStartPlaying()
        delegate?.didSwitchToTrack(index: index)
    }
    
    public func playNextTrack() {
        if currentTrackIndex + 1 < playlist.count {
            playTrack(at: currentTrackIndex + 1)
        } else {
            stop()
        }
    }
    
    public func playPreviousTrack() {
        if currentTrackIndex > 0 {
            playTrack(at: currentTrackIndex - 1)
        }
    }
    
    public func play() {
        player?.play()
        delegate?.didStartPlaying()
    }
    
    public func pause() {
        player?.pause()
        delegate?.didPause()
    }
    
    public func stop() {
        player?.pause()
        player?.seek(to: .zero)
        delegate?.didStop()
    }
    
    public func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    public func setPlaylist(_ urls: [URL]) {
        playlist = urls
        currentTrackIndex = 0
        if !urls.isEmpty {
            loadTrack(at: 0)
        }
    }
}

// MARK: - Private methods
private extension AVPlayerWrapper {
    
    private func loadTrack(at index: Int) {
        guard let url = playlist[safe: index] else {
            return
        }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        getCurrentDuration { duration in
            self.delegate?.didUpdateTime(currentTime: CMTime(), duration: duration ?? CMTime())
            self.timeObserverToken = self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
                guard let self = self,
                      let currentItem = self.playerItem else {
                    return
                }
                self.delegate?.didUpdateTime(currentTime: time, duration: duration ?? CMTime())
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    func getCurrentDuration(callback: ((_: CMTime?) -> Void)?) {
        guard let playerItem = self.playerItem,
              let player = self.player else {
            callback?(nil)
            return
        }
        if #available(iOS 15, *) {
            Task {
                do {
                    let asyncDuration = try await player.currentItem?.asset.load(.duration)
                    DispatchQueue.main.async {
                        callback?(asyncDuration)
                    }
                } catch {
                    callback?(nil)
                }
            }
        } else {
            let duration = player.currentItem?.asset.duration
            callback?(duration)
        }
    }
    
    @objc
    func playerDidFinishPlaying() {
        delegate?.didFinishPlaying()
        playNextTrack()
    }
}
