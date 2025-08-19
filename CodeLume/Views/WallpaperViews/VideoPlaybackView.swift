import AppKit
import AVKit

class VideoPlaybackView: AVPlayerView {
    // 播放状态属性
    var isPlaying: Bool {
        get {
            return player?.rate != 0
        }
        set {
            if newValue {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }

    func startMonitoringNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }

    func releaseResources() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }


    @objc private func handlePlaybackDidEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero) {
                [weak self] _ in
                self?.player?.play()
            }
        }
    }

    deinit {
        releaseResources()
    }

    // 音量控制
    var volume: Float {
        get {
            return player?.volume ?? 0.0
        }
        set {
            player?.volume = newValue
        }
    }
    
    init(frame: NSRect, config: ScreenConfiguration) {
        super.init(frame: frame)
        setupPlayer(with: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(with config: ScreenConfiguration) {
        if let url = config.contentUrl {
            let player = AVPlayer(url: url)
            self.player = player
            player.volume = config.volume
            player.isMuted = !config.isMainScreen
            // 暂时默认使用 Fill 填充方式, 其他方式保留
            self.videoGravity = .resizeAspectFill
            // setVideoFillMode(config.videoFillMode)
            startMonitoringNotification()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(name: .setWallpaperIsVisible, object: config.screenIdentifier, userInfo: ["isVisible": true])
                player.play()
            }
        }
    }

    private func setVideoFillMode(_ mode: VideoFillMode) {
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
