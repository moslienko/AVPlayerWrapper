//
//  PlaylistViewController.swift
//  AVPlayerWrapperExample
//
//  Created by Pavel Moslienko on 03.07.2024.
//

import AppViewUtilits
import AVFoundation
import MediaPlayer
import AVPlayerWrapper
import UIKit

extension DecorateWrapper where Element: UIButton {
    static func playerButtonStyle() -> DecorateWrapper {
        .wrap {
            $0.tintColor = .white
            $0.backgroundColor = .systemRed
            $0.layer.cornerRadius = 32
        }
    }
    
    static func smallIconButtonStyle() -> DecorateWrapper {
        .wrap {
            $0.tintColor = .label
            $0.backgroundColor = .clear
        }
    }
}

final class PlaylistViewController: UIViewController {
    
    let viewModel = PlaylistViewModel()
    
    // MARK: - UI components
    lazy var playPauseButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.playerButtonStyle())
        button.setImage(UIImage(systemName: "play.fill"), for: [])
        button.addAction {
            self.playPauseTapped()
        }
        
        return button
    }()
    
    lazy var nextTrackButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.playerButtonStyle())
        button.setImage(UIImage(systemName: "chevron.right"), for: [])
        button.addAction {
            self.nextTrackTapped()
        }
        
        return button
    }()
    
    lazy var previousTrackButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.playerButtonStyle())
        button.setImage(UIImage(systemName: "chevron.left"), for: [])
        button.addAction {
            self.previousTrackTapped()
        }
        
        return button
    }()
    
    lazy var speedTrackButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.smallIconButtonStyle())
        button.showsMenuAsPrimaryAction = true
        configureSpeedTrackButton(button)
        return button
    }()
    
    lazy var autoStopButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.smallIconButtonStyle())
        button.showsMenuAsPrimaryAction = true
        configureAutoStopButton(button)
        return button
    }()
    
    lazy var seekSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(seekSliderChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(seekSliderChangedValueFinished(_:)), for: .touchUpInside)
        
        return slider
    }()
    
    lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .label
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .left
        
        return label
    }()
    
    lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .label
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .right
        
        return label
    }()
    
    lazy var seekBackButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.smallIconButtonStyle())
        button.setImage(UIImage(systemName: "gobackward.5"), for: [])
        button.addAction {
            self.seekBackTapped()
        }
        
        return button
    }()
    
    lazy var seekForwardButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.smallIconButtonStyle())
        button.setImage(UIImage(systemName: "goforward.15"), for: [])
        button.addAction {
            self.seekForwardTapped()
        }
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.musicPlayer.delegate = self
        setupUI()
        reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.musicPlayer.stop()
    }
    
    func reloadData() {
        viewModel.musicPlayer.setPlaylist(viewModel.musicFiles)
        viewModel.musicPlayer.options.isDisplayNowPlaying = true
    }
}

// MARK: - Setup methods
private extension PlaylistViewController {
    
    func setupUI() {
        self.title = "Playlist"
        self.view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(playPauseButton)
        view.addSubview(previousTrackButton)
        view.addSubview(nextTrackButton)
        view.addSubview(seekBackButton)
        view.addSubview(seekForwardButton)
        view.addSubview(seekSlider)
        view.addSubview(currentTimeLabel)
        view.addSubview(durationLabel)
        view.addSubview(speedTrackButton)
        view.addSubview(autoStopButton)

        layoutUI()
    }
    
    func layoutUI() {
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        nextTrackButton.translatesAutoresizingMaskIntoConstraints = false
        seekBackButton.translatesAutoresizingMaskIntoConstraints = false
        seekForwardButton.translatesAutoresizingMaskIntoConstraints = false
        previousTrackButton.translatesAutoresizingMaskIntoConstraints = false
        seekSlider.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        speedTrackButton.translatesAutoresizingMaskIntoConstraints = false
        autoStopButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            playPauseButton.widthAnchor.constraint(equalToConstant: 64.0),
            playPauseButton.heightAnchor.constraint(equalToConstant: 64.0),
            
            previousTrackButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -20),
            previousTrackButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            previousTrackButton.widthAnchor.constraint(equalToConstant: 64.0),
            previousTrackButton.heightAnchor.constraint(equalToConstant: 64.0),
            
            nextTrackButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 20),
            nextTrackButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            nextTrackButton.widthAnchor.constraint(equalToConstant: 64.0),
            nextTrackButton.heightAnchor.constraint(equalToConstant: 64.0),
            
            seekBackButton.trailingAnchor.constraint(equalTo: previousTrackButton.leadingAnchor, constant: -20),
            seekBackButton.centerYAnchor.constraint(equalTo: previousTrackButton.centerYAnchor),
            seekBackButton.widthAnchor.constraint(equalToConstant: 42.0),
            seekBackButton.heightAnchor.constraint(equalToConstant: 42.0),
            
            seekForwardButton.leadingAnchor.constraint(equalTo: nextTrackButton.trailingAnchor, constant: 20),
            seekForwardButton.centerYAnchor.constraint(equalTo: nextTrackButton.centerYAnchor),
            seekForwardButton.widthAnchor.constraint(equalToConstant: 42.0),
            seekForwardButton.heightAnchor.constraint(equalToConstant: 42.0),
            
            seekSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            seekSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            seekSlider.topAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 30),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: seekSlider.leadingAnchor),
            currentTimeLabel.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 10),
            
            durationLabel.trailingAnchor.constraint(equalTo: seekSlider.trailingAnchor),
            durationLabel.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 10),
            
            speedTrackButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20),
            speedTrackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            speedTrackButton.widthAnchor.constraint(equalToConstant: 42.0),
            speedTrackButton.heightAnchor.constraint(equalToConstant: 42.0),
            
            autoStopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20),
            autoStopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            autoStopButton.widthAnchor.constraint(equalToConstant: 42.0),
            autoStopButton.heightAnchor.constraint(equalToConstant: 42.0)
        ])
    }
    
    func configureSpeedTrackButton(_ button: UIButton) {
        let rate = self.viewModel.musicPlayer.getPlayerRate() ?? 1.0
        button.setTitle(String(rate), for: [])
        
        var childrens: [UIMenuElement] = []
        let values: [Float] = [0.75, 1, 1.25, 1.5, 1.75, 2]
        values.forEach { value in
            let action = UIAction(
                title: "\(value) x",
                image: rate == value ? UIImage(systemName: "checkmark") : nil
            ) { _ in
                self.viewModel.musicPlayer.setPlaybackRate(to: value)
                self.configureSpeedTrackButton(button)
            }
            childrens.append(action)
        }
        
        button.menu = UIMenu(children: childrens)
    }
    
    func configureAutoStopButton(_ button: UIButton) {
        let type = self.viewModel.musicPlayer.autoStopType
        button.setTitle(getTitle(for: type), for: [])
        
        var childrens: [UIMenuElement] = []
        let values: [AVPlayerAutoStopType] = [.afterTrackEnd, .after(15), .after(30), .after(60), .disable]
        values.forEach { value in
            let title = getTitle(for: value)
            let action = UIAction(
                title: title,
                image: getTitle(for: type) == title ? UIImage(systemName: "checkmark") : nil
            ) { _ in
                self.viewModel.musicPlayer.setupAutoStop(with: value)
                self.configureAutoStopButton(button)
            }
            childrens.append(action)
        }
        
        button.menu = UIMenu(children: childrens)
        
        func getTitle(for type: AVPlayerAutoStopType) -> String {
            switch type {
            case .disable:
                return "Off"
            case .afterTrackEnd:
                return "After the end of the track"
            case let .after(seconds):
                return "After \(seconds)"
            }
        }
    }
}

// MARK: - Actions
private extension PlaylistViewController {
    
    func playPauseTapped() {
        viewModel.musicPlayer.isPlaying ? viewModel.musicPlayer.pause() : viewModel.musicPlayer.play()
    }
    
    func nextTrackTapped() {
        viewModel.musicPlayer.playNextTrack()
    }
    
    func previousTrackTapped() {
        viewModel.musicPlayer.playPreviousTrack()
    }
    
    func seekBackTapped() {
        viewModel.musicPlayer.seekBackward(by: 5)
    }
    
    func seekForwardTapped() {
        print("seekForwardTapped..")
        viewModel.musicPlayer.seekForward(by: 15)
    }
    
    @objc
    func seekSliderChanged(_ slider: UISlider) {
        viewModel.musicPlayer.pause()
        let seekTime = CMTime(seconds: Double(seekSlider.value), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let currentSeconds = CMTimeGetSeconds(seekTime)
        
        guard !currentSeconds.isNaN else {
            return
        }
        
        currentTimeLabel.text = formatTime(seconds: currentSeconds)
    }
    
    @objc
    func seekSliderChangedValueFinished(_ slider: UISlider) {
        let seekTime = CMTime(seconds: Double(seekSlider.value), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        viewModel.musicPlayer.seek(to: seekTime)
        viewModel.musicPlayer.play()
    }
    
    func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVPlayerWrapperDelegate
extension PlaylistViewController: AVPlayerWrapperDelegate {
    
    func didStartPlaying() {
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: [])
    }
    
    func didPause() {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: [])
    }
    
    func didStop() {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: [])
    }
    
    func didFinishPlaying() {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: [])
    }
    
    func didSwitchToTrack(index: Int) {
        previousTrackButton.isEnabled = index > 0
        nextTrackButton.isEnabled = index < viewModel.musicPlayer.playlist.count - 1
    }
    
    func didUpdateTime(time: AVAssetTime) {
        var currentSeconds: Float64 {
            let val = CMTimeGetSeconds(time.currentTime)
            return val.isNaN ? 0.0 : val
        }
        var durationSeconds: Float64 {
            let val = CMTimeGetSeconds(time.duration)
            return val.isNaN ? 0.0 : val
        }
        
        seekSlider.maximumValue = Float(durationSeconds)
        seekSlider.value = Float(currentSeconds)
        
        currentTimeLabel.text = formatTime(seconds: currentSeconds)
        durationLabel.text = formatTime(seconds: durationSeconds)
    }
    
    func didUpdateAutoStopTime(seconds: TimeInterval) {
        let title = formatTime(seconds: seconds)
        UIView.performWithoutAnimation {
            self.autoStopButton.setTitle(title, for: [])
            self.autoStopButton.layoutIfNeeded()
        }
    }
    
    func didUpdateAutoStopType(_ type: AVPlayerAutoStopType) {
        configureAutoStopButton(autoStopButton)
    }
    
    func didUpdateStatus(status: AVPlayerItem.Status) {
        switch status {
        case .unknown:
            print("Player status - unknown")
        case .readyToPlay:
            print("Player status - ready")
        case .failed:
            print("Player status - failed")
        @unknown default:
            break
        }
    }
    
    func didHandleError(error: Error?) {
        print("Player error - \(String(describing: error?.localizedDescription))")
    }
    
    func didFailedSetAudioSession(error: Error?) {
        print("Failed set session - \(String(describing: error?.localizedDescription))")
    }
}
