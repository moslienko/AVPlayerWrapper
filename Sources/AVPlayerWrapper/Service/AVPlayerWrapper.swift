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
    func didUpdateTime(time: AVAssetTime)
    func didUpdateAutoStopTime(seconds: TimeInterval)
    func didUpdateAutoStopType(_ type: AVPlayerAutoStopType)
    func didSwitchToTrack(index: Int)
    func didUpdateStatus(status: AVPlayerItem.Status)
    func didHandleError(error: Error?)
    func didFailedSetAudioSession(error: Error?)
}

public class AVPlayerWrapper: NSObject {
    
    // MARK: - Private variables
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var currentTrackIndex = 0
    private var timeObserverToken: Any?
    
    private lazy var nowPlayingService: NowPlayingService = {
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
    
    private lazy var autoStopService: AVPlayerAutoStopService = {
        let service: AVPlayerAutoStopService = AVPlayerAutoStopService(
            didStop: {
                self.stop()
            },
            didUpdateAutoStopTime: { remainingTime in
                onMainThread { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.didUpdateAutoStopTime?(remainingTime)
                    self.delegate?.didUpdateAutoStopTime(seconds: remainingTime)
                }
            },
            didUpdateAutoStopType: { type in
                onMainThread { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.didUpdateAutoStopType?(type)
                    self.delegate?.didUpdateAutoStopType(type)
                }
            }
        )
        
        return service
    }()
    
    // Key-value observing context
    private var playerItemContext = 0
    private let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    // MARK: - Public variables
    static public let shared = AVPlayerWrapper()
    
    public var playlist: [AVPlayerWrapperMediaFile] = []
    public var options: AVPlayerOptions
    
    public var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    // MARK: - Callbacks
    public weak var delegate: AVPlayerWrapperDelegate?
    
    public var didStartPlaying: Callback?
    public var didPause: Callback?
    public var didStop: Callback?
    public var didFinishPlaying: Callback?
    public var didUpdateTime: DataCallback<AVAssetTime>?
    public var didUpdateAutoStopTime: DataCallback<TimeInterval>?
    public var didUpdateAutoStopType: DataCallback<AVPlayerAutoStopType>?
    public var didSwitchToTrack: DataCallback<Int>?
    public var didUpdateStatus: DataCallback<AVPlayerItem.Status>?
    public var didHandleError: DataCallback<Error?>?
    public var didFailedSetAudioSession: DataCallback<Error?>?
    
    // MARK: - Init
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
        onMainThread { [weak self] in
            self?.didSwitchToTrack?(index)
            self?.delegate?.didSwitchToTrack(index: index)
        }
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
                self.autoStopService.startTimer()
                onMainThread { [weak self] in
                    self?.didStartPlaying?()
                    self?.delegate?.didStartPlaying()
                }
            }
        } else {
            self.player?.play()
            self.autoStopService.startTimer()
            onMainThread { [weak self] in
                self?.didStartPlaying?()
                self?.delegate?.didStartPlaying()
            }
        }
    }
    
    public func pause() {
        player?.pause()
        autoStopService.pauseTimer()
        onMainThread { [weak self] in
            self?.didPause?()
            self?.delegate?.didPause()
        }
    }
    
    public func stop() {
        player?.pause()
        player?.seek(to: .zero)
        
        autoStopService.cancelTimer()
        
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
            onMainThread { [weak self] in
                self?.didFailedSetAudioSession?(error)
                self?.delegate?.didFailedSetAudioSession(error: error)
            }
        }
        
        nowPlayingService.dismissRemoteCenter()
        onMainThread { [weak self] in
            self?.didStop?()
            self?.delegate?.didStop()
        }
    }
    
    public func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    public func setPlaybackRate(to rate: Float) {
        guard let player = player else { return }
        player.rate = max(0.5, min(rate, 2.0))
    }
    
    public func setupAutoStop(with type: AVPlayerAutoStopType) {
        autoStopService.setupAutoStop(with: type)
    }
    
    public func seekForward(by seconds: TimeInterval) {
        guard let player = player,
              let currentTime = player.currentItem?.currentTime() else {
            return
        }
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        let time = CMTimeMakeWithSeconds(newTime, preferredTimescale: currentTime.timescale)
        
        player.seek(to: time)
    }
    
    public func seekBackward(by seconds: TimeInterval) {
        guard let player = player,
              let currentTime = player.currentItem?.currentTime() else {
            return
        }
        let newTime = CMTimeGetSeconds(currentTime) - seconds
        let time = CMTimeMakeWithSeconds(newTime, preferredTimescale: currentTime.timescale)
        
        player.seek(to: time)
    }
    
    public func setPlaylist(
        _ files: [AVPlayerWrapperMediaFile],
        didStartPlaying: Callback? = nil,
        didPause: Callback? = nil,
        didStop: Callback? = nil,
        didFinishPlaying: Callback? = nil,
        didUpdateTime: DataCallback<AVAssetTime>? = nil,
        didSwitchToTrack: DataCallback<Int>? = nil,
        didUpdateStatus: DataCallback<AVPlayerItem.Status>? = nil,
        didHandleError: DataCallback<Error?>? = nil,
        didFailedSetAudioSession: DataCallback<Error?>? = nil
    ) {
        playlist = files
        currentTrackIndex = 0
        
        self.didStartPlaying = didStartPlaying
        self.didPause = didPause
        self.didStop = didStop
        self.didFinishPlaying = didFinishPlaying
        self.didUpdateTime = didUpdateTime
        self.didSwitchToTrack = didSwitchToTrack
        self.didUpdateStatus = didUpdateStatus
        self.didHandleError = didHandleError
        self.didFailedSetAudioSession = didFailedSetAudioSession
        
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
    
    public func getAutoStopType() -> AVPlayerAutoStopType {
        autoStopService.autoStopType
    }
}

// MARK: - Private methods
private extension AVPlayerWrapper {
    
    func loadTrack(at index: Int) {
        guard let url = playlist[safe: index]?.fileUrl else {
            return
        }
        
        playerItem = AVPlayerItem(url: url)
        playerItem?.addObserver(self,
                                forKeyPath: #keyPath(AVPlayerItem.status),
                                options: [.old, .new],
                                context: &playerItemContext)
        
        player = AVPlayer(playerItem: playerItem)
        player?.currentItem?.audioTimePitchAlgorithm = .timeDomain
        setupAVAudioSession()
        
        self.getCurrentDuration { duration in
            onMainThread { [weak self] in
                let timeModel = AVAssetTime(currentTime: CMTime(), duration: duration ?? CMTime())
                self?.didUpdateTime?(timeModel)
                self?.delegate?.didUpdateTime(time: timeModel)
            }
            self.timeObserverToken = self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
                guard let self = self,
                      let currentItem = self.playerItem else {
                    return
                }
                onMainThread { [weak self] in
                    let timeModel = AVAssetTime(currentTime: time, duration: duration ?? CMTime())
                    self?.didUpdateTime?(timeModel)
                    self?.delegate?.didUpdateTime(time: timeModel)
                }
            }
        }
        setupObservers()
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: self.playerItem, queue: .main) { notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            onMainThread { [weak self] in
                self?.didHandleError?(error)
                self?.delegate?.didHandleError(error: error)
            }
        }
        
        self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new, .initial], context: nil)
        self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.status), options:[.new, .initial], context: nil)
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
    
    func setupAVAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(options.session.category, mode: options.session.mode, options: options.session.options)
            try AVAudioSession.sharedInstance().setActive(true)
            
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch let error {
            onMainThread { [weak self] in
                self?.didFailedSetAudioSession?(error)
                self?.delegate?.didFailedSetAudioSession(error: error)
            }
        }
    }
    
    @objc
    func playerDidFinishPlaying() {
        onMainThread { [weak self] in
            self?.didFinishPlaying?()
            self?.delegate?.didFinishPlaying()
        }
        guard case let AVPlayerAutoStopType.afterTrackEnd = autoStopService.autoStopType else {
            playNextTrack()
            return
        }
        
        autoStopService.setupAutoStop(with: .disable)
        handleAutoStopAfterTrackEnd(nextAction: options.actionAfterAutoStopped)
    }
    
    func handleAutoStopAfterTrackEnd(nextAction: AVPlayerAfterAutoStopAction) {
        switch options.actionAfterAutoStopped {
        case .pauseCurrentTrack:
            pause()
        case .pauseAndLoadNextTrack:
            pause()
            if isCanPlayedNextAudio() {
                loadTrack(at: currentTrackIndex + 1)
            }
        case .resetCurrentTrack:
            pause()
            loadTrack(at: currentTrackIndex)
        case .stop:
            stop()
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            guard let status = self.player?.currentItem?.status else {
                return
            }
            var value = true
            switch status.rawValue {
            case 1:
                value = false
            default:
                value = true
            }
            
            if keyPath == #keyPath(AVPlayerItem.status) {
                let status: AVPlayerItem.Status
                if let statusNumber = change?[.newKey] as? NSNumber {
                    status = AVPlayerItem.Status(rawValue: statusNumber.intValue) ?? .unknown
                } else {
                    status = .unknown
                }
                onMainThread { [weak self] in
                    self?.didUpdateStatus?(status)
                    self?.delegate?.didUpdateStatus(status: status)
                }
            }
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
