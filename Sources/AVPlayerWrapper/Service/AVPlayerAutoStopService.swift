//
//  AVPlayerAutoStopService.swift
//
//
//  Created by Pavel Moslienko on 11.07.2024.
//
import AppViewUtilits
import Foundation
import MediaPlayer

/// A protocol that defines the delegate methods for the AVPlayerAutoStopService service.
public protocol AVPlayerAutoStopServiceDelegate: AnyObject {
    
    /// Indicates whether the media is currently being played.
    /// - Returns: A Boolean value indicating whether the media is currently being played.
    func isPlayedNow() -> Bool
}

/// A service that manages the auto-stop playing for an AVPlayer.
public class AVPlayerAutoStopService {
    
    // MARK: - Public variables
    public weak var delegate: AVPlayerAutoStopServiceDelegate?
    
    /// The type of auto-stop currently set.
    public private(set) var autoStopType: AVPlayerAutoStopType = .disable
    
    // MARK: - Callbacks
    
    /// A callback that gets invoked when playback stops due to the auto-stop playing.
    var didStop: Callback?
    
    /// A callback that gets invoked when the remaining auto-stop time is updated.
    var didUpdateAutoStopTime: DataCallback<TimeInterval>?
    
    /// A callback that gets invoked when the auto-stop type is updated.
    var didUpdateAutoStopType: DataCallback<AVPlayerAutoStopType>?
    
    // MARK: - Private variables
    
    /// The timer used for the auto-stop playing.
    private var autoStopTimer: Timer?
    
    /// The remaining time for the auto-stop playing.
    private var remainingTime: TimeInterval = 0
    
    // MARK: - Init
    
    /// Initializes a new instance of the AVPlayerAutoStopService with the provided callbacks.
    ///
    /// - Parameters:
    ///   - delegate: An optional `AVPlayerAutoStopServiceDelegate` to handle playback-related actions.
    ///   - didStop: A callback to be invoked when playback stops due to the auto-stop feature.
    ///   - didUpdateAutoStopTime: A callback to be invoked when the remaining auto-stop time is updated.
    ///   - didUpdateAutoStopType: A callback to be invoked when the auto-stop type is updated.
    public init(
        delegate: AVPlayerAutoStopServiceDelegate?,
        didStop: Callback?,
        didUpdateAutoStopTime: DataCallback<TimeInterval>? = nil,
        didUpdateAutoStopType: DataCallback<AVPlayerAutoStopType>? = nil
    ) {
        self.delegate = delegate
        self.didStop = didStop
        self.didUpdateAutoStopTime = didUpdateAutoStopTime
        self.didUpdateAutoStopType = didUpdateAutoStopType
    }
}

// MARK: - Public methods
public extension AVPlayerAutoStopService {
    
    /// Sets up the auto stop playing with the specified type.
    /// - Parameter type: The type of auto-stop to be set.
    public func setupAutoStop(with type: AVPlayerAutoStopType) {
        self.autoStopType = type
        switch type {
        case .disable, .afterTrackEnd:
            autoStopTimer?.invalidate()
            autoStopTimer = nil
        case let .after(seconds):
            remainingTime = seconds
            startTimer()
        }
    }
    
    /// Try starts the auto-stop player timer, if needed.
    public func startTimer() {
        switch self.autoStopType {
        case .disable:
            break
        default:
            let isPlayedNow = self.delegate?.isPlayedNow() ?? false
            guard isPlayedNow else {
                return
            }
            autoStopTimer?.invalidate()
            autoStopTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateRemainingTime), userInfo: nil, repeats: true)
            if let autoStopTimer = autoStopTimer {
                RunLoop.main.add(autoStopTimer, forMode: .common)
            }
        }
    }
    
    /// Pause the auto-stop player timer.
    public func pauseTimer() {
        autoStopTimer?.invalidate()
    }
    
    /// Cancel the auto-stop player timer.
    public func cancelTimer() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        autoStopType = .disable
    }
}

// MARK: - Private methods
private extension AVPlayerAutoStopService {
    
    /// Stops playing after the timer has elapsed.
    @objc
    func stopPlayingAfterTimer() {
        onMainThread { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.didStop?()
            strongSelf.didUpdateAutoStopType?(strongSelf.autoStopType)
        }
    }
    
    /// Updates the remaining time for the auto-stop playing.
    @objc
    func updateRemainingTime() {
        remainingTime -= 1
        onMainThread { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.didUpdateAutoStopTime?(strongSelf.remainingTime)
        }
        if remainingTime <= 0 {
            stopPlayingAfterTimer()
        }
    }
}
