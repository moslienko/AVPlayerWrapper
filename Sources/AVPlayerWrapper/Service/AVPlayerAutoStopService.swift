//
//  AVPlayerAutoStopService.swift
//
//
//  Created by Pavel Moslienko on 11.07.2024.
//
import AppViewUtilits
import Foundation
import MediaPlayer

public class AVPlayerAutoStopService {
    
    // MARK: - Public variables
    public private(set) var autoStopType: AVPlayerAutoStopType = .disable
    
    // MARK: - Callbacks
    var didStop: Callback?
    var didUpdateAutoStopTime: DataCallback<TimeInterval>?
    var didUpdateAutoStopType: DataCallback<AVPlayerAutoStopType>?
    
    // MARK: - Private variables
    private var autoStopTimer: Timer?
    private var remainingTime: TimeInterval = 0
    
    // MARK: - Init
    public init(didStop: Callback?,
                didUpdateAutoStopTime: DataCallback<TimeInterval>? = nil,
                didUpdateAutoStopType: DataCallback<AVPlayerAutoStopType>? = nil
    ) {
        self.didStop = didStop
        self.didUpdateAutoStopTime = didUpdateAutoStopTime
        self.didUpdateAutoStopType = didUpdateAutoStopType
    }
}

// MARK: - Public methods
public extension AVPlayerAutoStopService {
    
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
    
    public func startTimer() {
        print("AVPlayerAutoStopType - \( self.autoStopType)")
        guard case let AVPlayerAutoStopType.disable = self.autoStopType else {
            autoStopTimer?.invalidate()
            autoStopTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateRemainingTime), userInfo: nil, repeats: true)
            if let autoStopTimer = autoStopTimer {
                RunLoop.main.add(autoStopTimer, forMode: .common)
            }
            
            return
        }
    }
    
    public func pauseTimer() {
        autoStopTimer?.invalidate()
    }
    
    public func cancelTimer() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        autoStopType = .disable
    }
}

// MARK: - Private methods
private extension AVPlayerAutoStopService {
    
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
