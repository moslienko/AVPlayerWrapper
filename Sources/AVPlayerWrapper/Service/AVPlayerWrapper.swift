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

/// A protocol that defines the delegate methods for the AVPlayerWrapper.
public protocol AVPlayerWrapperDelegate: AnyObject {
    
    /// Called when playback starts.
    func didStartPlaying()
    
    /// Called when playback is paused.
    func didPause()
    
    /// Called when playback is stopped.
    func didStop()
    
    /// Called when playback finished.
    func didFinishPlaying()
    
    /// Called when the playback time is updated.
    /// - Parameter time: The current playback time.
    func didUpdateTime(time: AVAssetTime)
    
    /// Called when the remaining auto-stop time is updated.
    /// - Parameter seconds: The remaining time in seconds.
    func didUpdateAutoStopTime(seconds: TimeInterval)
    
    /// Called when the auto-stop type is updated.
    /// - Parameter type: The new auto-stop type.
    func didUpdateAutoStopType(_ type: AVPlayerAutoStopType)
    
    /// Called when the track is switched.
    /// - Parameter index: The index of the new track.
    func didSwitchToTrack(index: Int)
    
    /// Called when the status of the player item is updated.
    /// - Parameter status: The new status.
    func didUpdateStatus(status: AVPlayerItem.Status)
    
    /// Called when an error is handled.
    /// - Parameter error: The error that occurred.
    func didHandleError(error: Error?)
    
    /// Called when setting the audio session fails.
    /// - Parameter error: The error that occurred during setting the audio session.
    func didFailedSetAudioSession(error: Error?)
}

/// A wrapper class for AVPlayer
public class AVPlayerWrapper: NSObject {
    
    // MARK: - Private variables
    
    /// The underlying AVPlayer instance.
    private var player: AVPlayer?
    
    /// The current AVPlayerItem being played.
    private var playerItem: AVPlayerItem?
    
    /// The index of the current track in the playlist.
    private var currentTrackIndex = 0
    
    /// The token for the time observer.
    private var timeObserverToken: Any?
    
    // MARK: - Services
    
    /// The default service for managing now playing information.
    private lazy var defaultNowPlayingService: NowPlayingInfoCenterService = {
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
    
    
    /// The service for managing auto-stop functionality.
    private lazy var autoStopService: AVPlayerAutoStopService = {
        let service: AVPlayerAutoStopService = AVPlayerAutoStopService(
            delegate: self,
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
    
    /// Key-value observing context for player item.
    private var playerItemContext = 0
    
    /// The asset keys required for playing.
    private let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    // MARK: - Public variables
    
    /// The shared singleton instance of AVPlayerWrapper.
    static public let shared = AVPlayerWrapper()
    
    /// The playlist of media files to be played.
    public var playlist: [AVPlayerWrapperMediaFile] = []
    
    /// The options for the AVPlayerWrapper.
    public var options: AVPlayerOptions
    
    /// The service for managing now playing information.
    public var nowPlayingService: NowPlayingInfoCenterService?
    
    /// Indicates whether the player is currently playing.
    public var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    // MARK: - Callbacks
    public weak var delegate: AVPlayerWrapperDelegate?
    
    /// A callback that gets invoked when playback starts.
    public var didStartPlaying: Callback?
    
    /// A callback that gets invoked when playback is paused.
    public var didPause: Callback?
    
    /// A callback that gets invoked when playback is stopped.
    public var didStop: Callback?
    
    /// A callback that gets invoked when playback finishes.
    public var didFinishPlaying: Callback?
    
    /// A callback that gets invoked when the playback time is updated.
    public var didUpdateTime: DataCallback<AVAssetTime>?
    
    /// A callback that gets invoked when the remaining auto-stop time is updated.
    public var didUpdateAutoStopTime: DataCallback<TimeInterval>?
    
    /// A callback that gets invoked when the auto-stop type is updated.
    public var didUpdateAutoStopType: DataCallback<AVPlayerAutoStopType>?
    
    /// A callback that gets invoked when the track is switched.
    public var didSwitchToTrack: DataCallback<Int>?
    
    /// A callback that gets invoked when the status of the player item is updated.
    public var didUpdateStatus: DataCallback<AVPlayerItem.Status>?
    
    /// A callback that gets invoked when an error is handled.
    public var didHandleError: DataCallback<Error?>?
    
    /// A callback that gets invoked when setting the audio session fails.
    public var didFailedSetAudioSession: DataCallback<Error?>?
    
    // MARK: - Init
    
    /// Initializes a new instance of AVPlayerWrapper with default options and services.
    public override init() {
        self.options = AVPlayerOptions(isDisplayNowPlaying: false)
        super.init()
        self.nowPlayingService = self.defaultNowPlayingService
    }
    
    // Sets the playlist and optional callbacks for playback events.
    /// - Parameters:
    ///   - file: The array of media files to be set as the playlist.
    ///   - options: Player configuration.
    ///   - didStartPlaying: An optional callback to be invoked when playback starts.
    ///   - didPause: An optional callback to be invoked when playback is paused.
    ///   - didStop: An optional callback to be invoked when playback is stopped.
    ///   - didFinishPlaying: An optional callback to be invoked when playback finishes.
    ///   - didUpdateTime: An optional callback to be invoked when the playback time is updated.
    ///   - didSwitchToTrack: An optional callback to be invoked when the track is switched.
    ///   - didUpdateStatus: An optional callback to be invoked when the status of the player item is updated.
    ///   - didHandleError: An optional callback to be invoked when an error is handled.
    ///   - didFailedSetAudioSession: An optional callback to be invoked when setting the audio session fails.
    public init(
        _ file: AVPlayerWrapperMediaFile,
        options: AVPlayerOptions = AVPlayerOptions(isDisplayNowPlaying: false),
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
        self.playlist = [file]
        self.currentTrackIndex = 0
        self.options = options

        self.didStartPlaying = didStartPlaying
        self.didPause = didPause
        self.didStop = didStop
        self.didFinishPlaying = didFinishPlaying
        self.didUpdateTime = didUpdateTime
        self.didSwitchToTrack = didSwitchToTrack
        self.didUpdateStatus = didUpdateStatus
        self.didHandleError = didHandleError
        self.didFailedSetAudioSession = didFailedSetAudioSession
        
        super.init()
        self.loadTrack(at: 0)
    }
}

// MARK: - Public methods
public extension AVPlayerWrapper {
    
    /// Plays the track at the specified index in the playlist.
    /// - Parameter index: The index of the track to be played.
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
    
    /// Plays the next track in the playlist.
    public func playNextTrack() {
        if isCanPlayedNextAudio() {
            playTrack(at: currentTrackIndex + 1)
        } else {
            stop()
        }
    }
    
    /// Plays the previous track in the playlist.
    public func playPreviousTrack() {
        if isCanPlayedPrevAudio() {
            playTrack(at: currentTrackIndex - 1)
        }
    }
    
    /// Starts playback of the current track.
    public func play() {
        if options.isDisplayNowPlaying, let nowPlayingService = self.nowPlayingService {
            nowPlayingService.setupNowPlaying {
                startPlaying()
            }
        } else {
            startPlaying()
        }
        
        func startPlaying() {
            self.player?.play()
            self.autoStopService.startTimer()
            onMainThread { [weak self] in
                self?.didStartPlaying?()
                self?.delegate?.didStartPlaying()
            }
        }
    }
    
    /// Pauses playback of the current track.
    public func pause() {
        player?.pause()
        autoStopService.pauseTimer()
        onMainThread { [weak self] in
            self?.didPause?()
            self?.delegate?.didPause()
        }
    }
    
    /// Stops playback of the current track.
    public func stop() {
        player?.pause()
        player?.seek(to: .zero)
        
        autoStopService.cancelTimer()
        
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        removeObservers()
        
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
        
        nowPlayingService?.dismissRemoteCenter()
        onMainThread { [weak self] in
            self?.didStop?()
            self?.delegate?.didStop()
        }
    }
    
    /// Seeks to the specified time in the current track.
    /// - Parameter time: The time to seek to.
    public func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    /// Sets the playback rate of the player.
    /// - Parameter rate: The new playback rate.
    public func setPlaybackRate(to rate: Float) {
        guard let player = player else { return }
        player.rate = max(0.5, min(rate, 2.0))
    }
    
    /// Sets up the auto-stop feature with the specified type.
    /// - Parameter type: The type of auto-stop to be set.
    public func setupAutoStop(with type: AVPlayerAutoStopType) {
        autoStopService.setupAutoStop(with: type)
    }
    
    /// Seeks forward by the specified number of seconds in the current track.
    /// - Parameter seconds: The number of seconds to seek forward.
    public func seekForward(by seconds: TimeInterval) {
        guard let player = player,
              let currentTime = player.currentItem?.currentTime() else {
            return
        }
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        let time = CMTimeMakeWithSeconds(newTime, preferredTimescale: currentTime.timescale)
        
        player.seek(to: time)
    }
    
    /// Seeks backward by the specified number of seconds in the current track.
    /// - Parameter seconds: The number of seconds to seek backward.
    public func seekBackward(by seconds: TimeInterval) {
        guard let player = player,
              let currentTime = player.currentItem?.currentTime() else {
            return
        }
        let newTime = CMTimeGetSeconds(currentTime) - seconds
        let time = CMTimeMakeWithSeconds(newTime, preferredTimescale: currentTime.timescale)
        
        player.seek(to: time)
    }
    
    // Sets the playlist and optional callbacks for playback events.
    /// - Parameters:
    ///   - files: The array of media files to be set as the playlist.
    ///   - didStartPlaying: An optional callback to be invoked when playback starts.
    ///   - didPause: An optional callback to be invoked when playback is paused.
    ///   - didStop: An optional callback to be invoked when playback is stopped.
    ///   - didFinishPlaying: An optional callback to be invoked when playback finishes.
    ///   - didUpdateTime: An optional callback to be invoked when the playback time is updated.
    ///   - didSwitchToTrack: An optional callback to be invoked when the track is switched.
    ///   - didUpdateStatus: An optional callback to be invoked when the status of the player item is updated.
    ///   - didHandleError: An optional callback to be invoked when an error is handled.
    ///   - didFailedSetAudioSession: An optional callback to be invoked when setting the audio session fails.
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
    
    /// Indicates whether the previous audio track can be played.
    /// - Returns: A Boolean value indicating whether the previous audio track can be played.
    public func isCanPlayedPrevAudio() -> Bool {
        return currentTrackIndex > 0
    }
    
    /// Indicates whether the next audio track can be played.
    /// - Returns: A Boolean value indicating whether the next audio track can be played.
    public func isCanPlayedNextAudio() -> Bool {
        return currentTrackIndex + 1 < playlist.count
    }
    
    /// Gets the current auto-stop type.
    /// - Returns: The current auto-stop type.
    public func getAutoStopType() -> AVPlayerAutoStopType {
        return autoStopService.autoStopType
    }
}

// MARK: - Private methods
private extension AVPlayerWrapper {
    
    /// Loads the track at the specified index in the playlist.
    /// - Parameter index: The index of the track to be loaded.
    func loadTrack(at index: Int) {
        guard let url = playlist[safe: index]?.fileUrl else {
            return
        }
        
        playerItem = AVPlayerItem(url: url)
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
    
    /// Sets up observers for the player item and playback time.
    func setupObservers() {
        // Add notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: self.playerItem, queue: .main) { notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            onMainThread { [weak self] in
                self?.didHandleError?(error)
                self?.delegate?.didHandleError(error: error)
            }
        }
        
        // Add key-value observers
        self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.status), options:[.new, .initial], context: nil)
        self.playerItem?.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.old, .new, .initial],
            context: &playerItemContext
        )
    }
    
    /// Removes the observers for the notifications and key-value observations set up in `setupObservers`.
    func removeObservers() {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: self.playerItem)
        
        // Remove key-value observers
        self.player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.status))
        self.playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status))
    }
    
    /// Gets the current duration of the player item.
    /// - Parameter callback: A closure to be executed with the current duration as `CMTime?`.
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
    
    /// Sets up the AVAudioSession for playback.
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
    
    /// Handles the event when the player finishes playing the current track.
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
    
    /// Handles the auto-stop action after the track ends.
    /// - Parameter nextAction: The action to be taken after the auto-stop.
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
    
    /// Observes changes in the specified key path for the given object.
    /// - Parameters:
    ///   - keyPath: The key path being observed.
    ///   - object: The object being observed.
    ///   - change: The dictionary containing the change details.
    ///   - context: The context for the observation.
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

// MARK: - NowPlayingServiceDelegate & AVPlayerAutoStopServiceDelegate
extension AVPlayerWrapper: NowPlayingServiceDelegate, AVPlayerAutoStopServiceDelegate {
    
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
