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
    
    lazy var nowPlayingService: NowPlayingService = {
        let service: NowPlayingService = NowPlayingService(
            delegate: self,
            didPlayButtonTapped: {
                self.play()
            },
            didPauseButtonTapped: {
                self.pause()
            },
            didPrevTrackButtonTapped: {
                self.playPreviousTrack()
            },
            didNextTrackButtonTapped: {
                self.playNextTrack()
            }
        )
        
        return service
    }()
    
    // MARK: - Public variables
    static public let shared = AVPlayerWrapper()
    
    public var playlist: [AVPlayerWrapperMediaFile] = []
    public var options: AVPlayerOptions
    
    public var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    // MARK: - Callbacks
    public weak var delegate: AVPlayerWrapperDelegate?
    
    private override init() {
        options = AVPlayerOptions(isDisplayNowPlaying: false)
    }
}

// MARK: - Public methods
public extension AVPlayerWrapper {
    
    public func playTrack(at index: Int) {
        guard index < playlist.count else {
            return
        }
        currentTrackIndex = index
        stop()
        loadTrack(at: index)
        play()
        delegate?.didSwitchToTrack(index: index)
    }
    
    public func playNextTrack() {
        if isCanPlayedNextAudio() {
            playTrack(at: currentTrackIndex + 1)
        } else {
            stop()
        }
    }
    
    public func playPreviousTrack() {
        if isCanPlayedPrevAudio() {
            playTrack(at: currentTrackIndex - 1)
        }
    }
    
    public func play() {
        if options.isDisplayNowPlaying {
            self.nowPlayingService.setupNowPlaying {
                self.player?.play()
                self.delegate?.didStartPlaying()
            }
        } else {
            self.player?.play()
            self.delegate?.didStartPlaying()
        }
    }
    
    public func pause() {
        player?.pause()
        delegate?.didPause()
    }
    
    public func stop() {
        player?.pause()
        player?.seek(to: .zero)
        
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        _ = MPRemoteCommandCenter.shared().stopCommand
        UIApplication.shared.endReceivingRemoteControlEvents()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error with setup AV session: \(error)")
        }
        nowPlayingService.dismissRemoteCenter()
        delegate?.didStop()
    }
    
    public func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    public func setPlaylist(_ files: [AVPlayerWrapperMediaFile]) {
        playlist = files
        currentTrackIndex = 0
        if !files.isEmpty {
            loadTrack(at: 0)
        }
    }
    
    public func isCanPlayedPrevAudio() -> Bool {
        currentTrackIndex > 0
    }
    
    public func isCanPlayedNextAudio() -> Bool {
        currentTrackIndex + 1 < playlist.count
    }
}

// MARK: - Private methods
private extension AVPlayerWrapper {
    
    private func loadTrack(at index: Int) {
        guard let url = playlist[safe: index]?.fileUrl else {
            return
        }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        setupAVAudioSession()
        print("loadTrack")
        self.getCurrentDuration { duration in
            print("loadTrack duration - \(duration)")
            self.delegate?.didUpdateTime(currentTime: CMTime(), duration: duration ?? CMTime())
            self.timeObserverToken = self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
                guard let self = self,
                      let currentItem = self.playerItem else {
                    return
                }
                self.delegate?.didUpdateTime(currentTime: time, duration: duration ?? CMTime())
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: self.playerItem, queue: .main) { notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("failed to play to end time - \(error.localizedDescription)")
            } else {
                print("failed to play to end time")
            }
        }
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

// MARK: - Player in command center and lockscreen
private extension AVPlayerWrapper {
    
    func setupAVAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(options.session.category, mode: options.session.mode, options: options.session.options)
            try AVAudioSession.sharedInstance().setActive(true)
            
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
    }
}

// MARK: - NowPlayingServiceDelegate
extension AVPlayerWrapper: NowPlayingServiceDelegate {
    
    public func isPlayedNow() -> Bool {
        isPlaying
    }
    
    public func getCurrentMediaFile() -> AVPlayerWrapperMediaFile? {
        playlist[safe: currentTrackIndex]
    }
    
    public func getPlayerAssetCurrentTime() -> Double? {
        playerItem?.currentTime().seconds
    }
    
    public func getPlayerAssetDuration() -> Double? {
        playerItem?.asset.duration.seconds
    }
    
    public func getPlayerRate() -> Float? {
        player?.rate
    }
}
