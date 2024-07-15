//
//  NowPlayingService.swift
//
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import AppViewUtilits
import Foundation
import MediaPlayer

/// A protocol that defines the delegate methods for the NowPlaying service.
public protocol NowPlayingServiceDelegate: AnyObject {
    
    /// Indicates whether the media is currently being played.
    /// - Returns: A Boolean value indicating whether the media is currently being played.
    func isPlayedNow() -> Bool
    
    /// Indicates whether the previous audio track can be played.
    /// - Returns: A Boolean value indicating whether the previous audio track can be played.
    func isCanPlayedPrevAudio() -> Bool
    
    /// Indicates whether the next audio track can be played.
    /// - Returns: A Boolean value indicating whether the next audio track can be played.
    func isCanPlayedNextAudio() -> Bool
    
    /// Provides the current media file being played.
    /// - Returns: An optional `AVPlayerWrapperMediaFile` object representing the current media file.
    func getCurrentMediaFile() -> AVPlayerWrapperMediaFile?
    
    /// Provides the current playback time of the player's asset.
    /// - Returns: An optional `Double` representing the current playback time in seconds.
    func getPlayerAssetCurrentTime() -> Double?
    
    /// Provides the duration of the player's asset.
    /// - Returns: An optional `Double` representing the duration of the asset in seconds.
    func getPlayerAssetDuration() -> Double?
    
    /// Provides the current playback rate of the player.
    /// - Returns: An optional `Float` representing the playback rate.
    func getPlayerRate() -> Float?
}

/// A protocol that defines the delegate methods for the service that setup the now playing info center for an AVPlayer.
public protocol NowPlayingInfoCenterService {
    
    /// Set up the now playing information
    /// - Parameter callback: A closure to be executed when the setup is complete.
    func setupNowPlaying(callback: @escaping (() -> Void))
    
    /// Dismisses the remote center, removing any displayed now playing information.
    func dismissRemoteCenter()
}

/// A service that setup the now playing info center for an AVPlayer.
public class NowPlayingService {
    
    // MARK: - Public variables
    
    public weak var delegate: NowPlayingServiceDelegate?
    
    // MARK: - Callbacks
    
    /// A callback that gets invoked when the play button is tapped.
    public var didPlayButtonTapped: Callback?
    
    /// A callback that gets invoked when the pause button is tapped.
    public var didPauseButtonTapped: Callback?
    
    /// A callback that gets invoked when the previous track button is tapped.
    public var didPrevTrackButtonTapped: Callback?
    
    /// A callback that gets invoked when the next track button is tapped.
    public var didNextTrackButtonTapped: Callback?
    
    // MARK: - Init
    
    /// Initializes a new instance of the NowPlayingService with the provided delegate and callbacks.
    ///
    /// - Parameters:
    ///   - delegate: An optional `NowPlayingServiceDelegate` to handle playback-related actions.
    ///   - didPlayButtonTapped: An optional callback to be invoked when the play button is tapped.
    ///   - didPauseButtonTapped: An optional callback to be invoked when the pause button is tapped.
    ///   - didPrevTrackButtonTapped: An optional callback to be invoked when the previous track button is tapped.
    ///   - didNextTrackButtonTapped: An optional callback to be invoked when the next track button is tapped.
    public init(delegate: NowPlayingServiceDelegate?,
                didPlayButtonTapped: Callback? = nil,
                didPauseButtonTapped: Callback? = nil,
                didPrevTrackButtonTapped: Callback? = nil,
                didNextTrackButtonTapped: Callback? = nil
    ) {
        self.delegate = delegate
        self.didPlayButtonTapped = didPlayButtonTapped
        self.didPauseButtonTapped = didPauseButtonTapped
        self.didPrevTrackButtonTapped = didPrevTrackButtonTapped
        self.didNextTrackButtonTapped = didNextTrackButtonTapped
    }
}

// MARK: - Public methods
extension NowPlayingService: NowPlayingInfoCenterService {
    
    public func setupNowPlaying(callback: @escaping (() -> Void)) {
        guard let item = self.delegate?.getCurrentMediaFile() else {
            callback()
            return
        }
        
        self.setupCoverForPlayingCenter(callback: { info in
            self.setupRemoteTransportControls()
            
            var nowPlayingInfo = info
            nowPlayingInfo[MPMediaItemPropertyTitle] = item.title
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.delegate?.getPlayerAssetCurrentTime()
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.delegate?.getPlayerAssetDuration()
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.delegate?.getPlayerRate()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            callback()
        })
    }
    
    public func dismissRemoteCenter() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.playCommand.isEnabled = false
        remoteCommandCenter.pauseCommand.isEnabled = false
        
        if #available(iOS 13.0, *) {
            MPNowPlayingInfoCenter.default().playbackState = .stopped
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

// MARK: - Private methods
private extension NowPlayingService {
    
    /// Sets up the cover image for the playing center.
    /// - Parameter callback: Playing center info with cover data.
    func setupCoverForPlayingCenter(callback: @escaping (([String : Any]) -> Void)) {
        var nowPlayingInfo = [String : Any]()
        guard let item = self.delegate?.getCurrentMediaFile() else {
            callback(nowPlayingInfo)
            return
        }
        
        guard let coverURL = item.coverUrl else {
            if let defaultCoverImage = item.coverImage {
                setImageInCover(defaultCoverImage)
            }
            callback(nowPlayingInfo)
            return
        }
        
        fetchRemoteCover(by: coverURL) { remoteCoverImg in
            if let remoteCoverImg = remoteCoverImg {
                setImageInCover(remoteCoverImg)
            }
            
            callback(nowPlayingInfo)
        }
        
        func setImageInCover(_ image: UIImage) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in
                return image
            })
        }
    }
    
    /// Fetch the remote cover image.
    /// - Parameters:
    ///   - url:  The URL from which to fetch the cover img.
    ///   - callback: A fetched image.
    func fetchRemoteCover(by url: URL, callback: @escaping ((UIImage?) -> Void)) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let data = data {
                    let image = UIImage(data: data)
                    callback(image)
                } else {
                    callback(nil)
                }
            }
        }
        
        task.resume()
    }
    
    /// Set up the remote transport control actions.
    func setupRemoteTransportControls() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.nextTrackCommand.isEnabled = self.delegate?.isCanPlayedNextAudio() ?? false
        commandCenter.previousTrackCommand.isEnabled = self.delegate?.isCanPlayedPrevAudio() ?? false
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            let isPlayedNow = self.delegate?.isPlayedNow() ?? false
            if !isPlayedNow {
                self.didPlayButtonTapped?()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            let isPlayedNow = self.delegate?.isPlayedNow() ?? false
            if isPlayedNow {
                self.didPauseButtonTapped?()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            guard self.delegate?.isCanPlayedPrevAudio() ?? false else {
                return .noActionableNowPlayingItem
            }
            self.didPrevTrackButtonTapped?()
            
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            guard self.delegate?.isCanPlayedNextAudio() ?? false else {
                return .noActionableNowPlayingItem
            }
            self.didNextTrackButtonTapped?()
            
            return .success
        }
    }
}
