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

    @objc private func handlePlaybackDidEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero) {
                [weak self] _ in
                self?.player?.play()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        self.controlsStyle = .none
        setupPlayer(with: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(with config: ScreenConfiguration) {
        if let url = config.contentUrl {
            let player = AVPlayer(url: url)
            self.player = player
            if config.isMainScreen {
                player.volume = config.volume
            } else {
                player.volume = 0.0
            }
            player.play()
        }
    }
}
