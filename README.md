<p align="center">
   <img width="200" src="https://moslienko.github.io/Assets/AVPlayerWrapper/sdk.png" alt="AVPlayerWrapper Logo">
</p>

<p align="center">
   <a href="https://developer.apple.com/swift/">
      <img src="https://img.shields.io/badge/Swift-5.2-orange.svg?style=flat" alt="Swift 5.2">
   </a>
   <a href="https://github.com/apple/swift-package-manager">
      <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
   </a>
</p>

# AVPlayerWrapper

<p align="center">
A wrapper for listening to local or remote music files singly or as a playlist
</p>

## Table of Contents

* [Installation](#installation)
* [Example](#example)
* [Usage](#usage)
	* [Basic](#basic)
	* [Playlist](#playlist)
	* [Seek](#seek)
	* [Playback speed](#playback-speed)
	* [Auto stop playing](#auto-stop-playing)
* [NowPlayingService](#nowplayingservice)
* [Options](#options)
* [License](#license)

## Installation
The library requires a dependency [AppViewUtilits](https://github.com/moslienko/AppViewUtilits/).

### Swift Package Manager

To integrate using Apple's [Swift Package Manager](https://swift.org/package-manager/), add the following as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/moslienko/AVPlayerWrapper.git", from: "1.0.1")
]
```

Alternatively navigate to your Xcode project, select `Swift Packages` and click the `+` icon to search for `AVPlayerWrapper`.

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate AVPlayerWrapper into your project manually. Simply drag the `Sources` Folder into your Xcode project.

## Example

The example application is the best way to see `AVPlayerWrapper` in action. Simply open the `AVPlayerWrapperExample.xcodeproj` and run the `AVPlayerWrapperExample` scheme.

## Usage

### Basic

The audio file is passed to the player through the creation of an object of the class `AVPlayerWrapperMediaFile`.

```swift
class AVPlayerWrapperMediaFile {

  /// The URL of the media file.
  var fileUrl: URL

  /// The title of the media file.
  var title: String?

  /// The URL of the cover image.
  var coverUrl: URL?

  /// The cover image.
  var coverImage: UIImage?
  
  /// Looping of file playback.
  var loopType: AVPlayerLoopType
}
```

The title and cover information is needed for displaying in `MPNowPlayingInfoCenter`.

In the most basic use case, playing a file is realized as follows:

```swift
if let url = Bundle.main.createFileUrl(forResource: "signal.mp3") {
  AVPlayerWrapper(AVPlayerWrapperMediaFile(fileUrl: url)).play()
}
```

Playing a file with receiving callbacks and displaying track information in the `MPNowPlayingInfoCenter`:

```swift
guard let url = URL(string: "example.com/audio.mp3") else {
  return
}
let file = AVPlayerWrapperMediaFile(
  fileUrl: url,
  title: "Music title",
  coverUrl: URL(string: "example.com/cover.png"),
  coverImage: UIImage(named: "default_cover")
)
let options = AVPlayerOptions(
  isDisplayNowPlaying: true,
  session: AVSession(
    category: .playback,
    mode: .default, options: []
  )
)
let player = AVPlayerWrapper(
  file,
  options: options,
  didStartPlaying: {
    print("didStartPlaying")
  },
  didPause: {

  },
  didStop: {

  },
  didFinishPlaying: {
    print("didFinishPlaying")
  },
  didUpdateTime: { time in

  },
  didSwitchToTrack: { _ in

  },
  didUpdateStatus: { status in

  },
  didHandleError: { error in

  },
  didFailedSetAudioSession: { error in

  }
)
player.play()
```


Callbacks can also be provided by setting the `AVPlayerWrapperDelegate` delegate:

```swift
let player = AVPlayerWrapper(file, options: options)
player.delegate = self
player.play()
```

The following methods are used to control track playback:

```swift
/// Starts playback of the current track.
func play()

/// Pauses playback of the current track.
func pause()

/// Stops playback of the current track.
func stop()
```

### Playlist

Multiple files can be set for the player at once, playing them as a playlist.

```swift
var musicFiles: [AVPlayerWrapperMediaFile] = []

if let url = URL(string: "http://example.com/audio_1.mp3") {
  musicFiles += [AVPlayerWrapperMediaFile(fileUrl: url, title: "Auduo 1")]
}
if let url = URL(string: "http://example.com/audio_2.mp3") {
  musicFiles += [AVPlayerWrapperMediaFile(fileUrl: url, title: "Auduo 2")]
}

AVPlayerWrapper.shared.setPlaylist(musicFiles)
```


The following methods are used to control playlist playback:

```swift
/// Plays the track at the specified index in the playlist.
/// - Parameter index: The index of the track to be played.
func playTrack(at index: Int)

/// Plays the next track in the playlist.
func playNextTrack()

/// Plays the previous track in the playlist.
func playPreviousTrack()
```

### Seek

Rewind the audio player to a specified time:

```swift
let seekTime = CMTime(seconds: Double(30.0), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
player.seek(to: seekTime)
```

Rewind playback to backward:

```swift
 player.seekBackward(by: 5)
```

Fast forward the audio player:

```swift
 player.seekForward(by: 15)
```

###  Playback speed

You can change the playback speed:

```swift
player.setPlaybackRate(to: 1.75)
```

### Auto stop playing

```swift
let player = AVPlayerWrapper.shared
player.setupAutoStop(with: .afterTrackEnd)
```

Auto-stop playing types for AVPlayer

```swift
enum AVPlayerAutoStopType {

  /// Auto-stop is disabled.
  case disable

  /// Auto-stop after the current track ends.
  case afterTrackEnd

  /// Auto-stop after a specified number of seconds.
  case after(_ seconds: TimeInterval)
}
```

When the playback auto stop value is set, use the following methods in the `AVPlayerWrapperDelegate` delegate or via callbacks, it will receive the timer value (how many seconds are left until the end of playback) and a new type of auto stop, which will be reset to `.disable` after the end of playback.

```swift
func didUpdateAutoStopTime(seconds: TimeInterval)
func didUpdateAutoStopType(_ type: AVPlayerAutoStopType)
```

If the auto stop type was specified as `.afterTrackEnd`, the action specified in the configuration as `actionAfterAutoStopped ` will be called after playback ends.

## NowPlayingService

You can override the service intended for configuration `MPNowPlayingInfoCenter`. It's set in the player's `nowPlayingService` variable.

```swift
protocol NowPlayingInfoCenterService {

  /// Set up the now playing information
  /// - Parameter callback: A closure to be executed when the setup is complete.
  func setupNowPlaying(callback: @escaping (() -> Void))

  /// Dismisses the remote center, removing any displayed now playing information.
  func dismissRemoteCenter()
}
```

## Options

### AVPlayerOptions

Options for configuring the AVPlayer

```swift
struct AVPlayerOptions {

  /// Indicates whether the now playing info should be displayed.
  public var isDisplayNowPlaying: Bool

  /// The action to be taken after the auto-stop.
  public var actionAfterAutoStopped: AVPlayerAfterAutoStopAction

  /// The AV audio session configuration.
  public var session: AVSession
  
  /// Delay for looping playback.
  public var loopDelay: Double
}
```

### AVSession

The AV audio session configuration.

```swift
struct AVSession {

  /// The category of the AV audio session.
  public var category: AVAudioSession.Category

  /// The mode of the AV audio session.
  public var mode: AVAudioSession.Mode

  /// The options for the AV audio session category.
  public var options: AVAudioSession.CategoryOptions
}
```


## License

```
AVPlayerWrapper
Copyright (c) 2024 Pavel Moslienko 8676976+moslienko@users.noreply.github.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
