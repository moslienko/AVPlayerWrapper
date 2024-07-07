//
//  NowPlayingService.swift
//
//
//  Created by Pavel Moslienko on 07.07.2024.
//

import AppViewUtilits
import Foundation
import MediaPlayer

public protocol NowPlayingServiceDelegate: AnyObject {
    func isPlayedNow() -> Bool
    func isCanPlayedPrevAudio() -> Bool
    func isCanPlayedNextAudio() -> Bool
    
    func getCurrentMediaFile() -> AVPlayerWrapperMediaFile?
    func getPlayerAssetCurrentTime() -> Double?
    func getPlayerAssetDuration() -> Double?
    func getPlayerRate() -> Float?
}

public class NowPlayingService {
    
    // MARK: - Public variables
    public weak var delegate: NowPlayingServiceDelegate?
    
    // MARK: - Callbacks
    var didPlayButtonTapped: Callback?
    var didPauseButtonTapped: Callback?
    var didPrevTrackButtonTapped: Callback?
    var didNextTrackButtonTapped: Callback?
    
    
    // MARK: - Init
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
public extension NowPlayingService {
    
    func setupNowPlaying(callback: @escaping (() -> Void)) {
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
    
    func dismissRemoteCenter() {
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
            print("isPlayedNow - \(isPlayedNow)")
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
