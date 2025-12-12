import AppKit
import AVKit
import AVFoundation

class VideoPlaybackView: NSView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isPlaying = true
    private var currentScreenPlayingState = true
    private var playScreen : NSScreen = NSScreen.main!
    private var pause: Bool = UserDefaultsManager.shared.getPauseStatus()
    private var mute: Bool = UserDefaultsManager.shared.getMuteStatus()
    private var volume: Float = UserDefaultsManager.shared.getVolume()

    func startMonitoringNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenPlayStateChanged),
            name: .screenPlayStateChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: .playbackStateChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePause),
            name: .pause,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMute),
            name: .mute,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVolume),
            name: .volume,
            object: nil
        )
    }

    func releaseResources() {
        Logger.info("Release video playback view resources. Screen: \(playScreen.identifier)")
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: .screenPlayStateChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .playbackStateChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .pause, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .volume, object: nil)
    }


    @objc private func handlePlaybackDidEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero) {
                [weak self] _ in
                self?.player?.play()
            }
        }
    }

    @objc private func handleScreenPlayStateChanged(notification: Notification) {
        if !isPlaying || pause {
            return
        }

        if let screenId = notification.object as? String {
            if screenId == playScreen.identifier {
                if let shouldPlay = notification.userInfo?["isPlaying"] as? Bool {
                    if shouldPlay {
                        Logger.info("Screen play state changed to playing.")
                        currentScreenPlayingState = true
                        if !pause && isPlaying {
                            player?.play()
                        }
                    } else {
                        Logger.info("Screen play state changed to paused.")
                        currentScreenPlayingState = false
                        player?.pause()
                        if let seekToZero = notification.userInfo?["seekToZero"] as? Bool {
                            if seekToZero {
                                player?.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
                            }
                        }
                    }
                }
            }
        }
    }

    @objc private func handlePlaybackStateChanged(notification: Notification) {
        if let isPlaying = notification.userInfo?["isPlaying"] as? Bool {
            if isPlaying {
                Logger.info("Playback state changed to playing.")
                self.isPlaying = true
                if !pause && currentScreenPlayingState {
                    player?.play()
                }
            } else {
                Logger.info("Playback state changed to paused.")
                self.isPlaying = false
                player?.pause()
                player?.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }

    @objc private func handlePause(notification: Notification) {
        if let pause = notification.object as? Bool {
            self.pause = pause
            if pause {
                player?.pause()
            } else {
                if isPlaying && currentScreenPlayingState {
                    player?.play()
                }
            }
        }
    }

    @objc private func handleMute(notification: Notification) {
        if let mute = notification.object as? Bool {
            self.mute = mute
            player?.isMuted = mute
        }
    }

    @objc private func handleVolume(notification: Notification) {
        if let volume = notification.object as? Float {
            self.volume = volume
            player?.volume = volume
        }
    }

    var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            playerLayer?.videoGravity = videoGravity
        }
    }
    
    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
    
    deinit {
        releaseResources()
    }
    
    init(frame: NSRect, config: ScreenConfiguration, screen: NSScreen) {
        super.init(frame: frame)
        setupPlayer(with: config)
        playScreen = screen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(with config: ScreenConfiguration) {
        if let url = config.contentUrl {
            let player = AVPlayer(url: url)
            self.player = player
            
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = bounds
            layer = playerLayer
            wantsLayer = true
            self.playerLayer = playerLayer
            
            player.volume = 0.0
            player.isMuted = mute
            
            startMonitoringNotification()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(name: .setWallpaperIsVisible, object: config.id, userInfo: ["isVisible": true])
                if !self.pause {
                    player.play()
                }
            }
        }
    }

    private func setVideoFillMode(_ mode: WallpaperFillMode) {
        switch mode {
        case .fit:
            self.videoGravity = .resizeAspect
        case .fill:
            self.videoGravity = .resizeAspectFill
        case .stretch:
            self.videoGravity = .resize
        }
    }
}
