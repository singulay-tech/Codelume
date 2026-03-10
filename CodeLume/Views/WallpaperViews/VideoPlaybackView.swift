import AppKit
import AVKit
import AVFoundation
import CodelumeBundle

class VideoPlaybackView: NSView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playScreen: NSScreen?
    private var screenConfiguration: ScreenConfiguration?
    private var globalPlaybackState: Bool = true
    private var globalTemporaryPause: Bool = false
    private var screenTemporaryPause: Bool = false
    private var globalSeekToZero: Bool = false
    private var screenSeekToZero: Bool = false
    
    init(frame: NSRect, config: ScreenConfiguration, screen: NSScreen) {
        super.init(frame: frame)
        screenConfiguration = config
        playScreen = screen
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        releaseResources()
    }
    
    private func setupPlayer() {
        guard let bundleUrl = screenConfiguration?.wallpaperUrl, bundleUrl.pathExtension == "bundle" else {
            Logger.error("Invalid or missing wallpaper bundle URL.")
            return
        }
        
        do {
            let videoUrl = try loadVideoUrl(from: bundleUrl)
            player = AVPlayer(url: videoUrl)
            setupPlayerLayer()
            applyPlaybackSettings()
            setupNotificationObservers()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Logger.info("Post visibility notification and start playback after delay for screen: \(self.screenConfiguration!.id)")
                NotificationCenter.default.post(name: .setWallpaperIsVisible,
                                                object: self.screenConfiguration?.id,
                                                userInfo: ["isVisible": true])
                self.applyPlaybackSettings()
            }
        } catch {
            Logger.error("Failed to setup video player: \(error)")
        }
    }
    
    private func setupPlayerLayer() {
        guard let player = player else { return }
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = bounds
        
        layer = playerLayer
        wantsLayer = true
    }
    
    private func loadVideoUrl(from bundleUrl: URL) throws -> URL {
        let bundle = VideoBundle()
        _ = bundle.open(wallpaperUrl: bundleUrl)
        return bundle.videoUrl!
    }
    
    private func applyPlaybackSettings() {
        guard let player = player, let config = screenConfiguration else { return }
        
        let globalVolume = UserDefaultsManager.shared.getVolume()
        let screenVolume = Float(config.volume)
        player.volume = globalVolume * screenVolume
        
        let globalMute = UserDefaultsManager.shared.getMuteStatus()
        player.isMuted = globalMute || config.isMuted
        
        let globalPause = UserDefaultsManager.shared.getPauseStatus()
        let shouldTemporarilyPause = globalTemporaryPause || screenTemporaryPause
        let shouldPlay = !globalPause && config.isPlaying && !shouldTemporarilyPause
        let shouldSeekToZero = globalSeekToZero || screenSeekToZero
        Logger.info("Screen: \(config.id), global volume: \(globalVolume), screen volume: \(screenVolume), final volume: \(globalVolume * screenVolume)")
        Logger.info("Screen: \(config.id), global mute: \(globalMute), screen mute: \(config.isMuted), final mute: \(player.isMuted)")
        Logger.info("Screen: \(config.id), global pause: \(globalPause), screen play: \(config.isPlaying), global temporary pause: \(globalTemporaryPause), screen temporary pause: \(screenTemporaryPause), final play: \(shouldPlay)")
        
        if shouldSeekToZero {
            player.seek(to: CMTime.zero)
        }
        
        shouldPlay ? player.play() : player.pause()
    }
    
    private func setupNotificationObservers() {
        let center = NotificationCenter.default
        
        center.addObserver(
            self,
            selector: #selector(handlePlaybackDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        center.addObserver(
            self,
            selector: #selector(handleScreenConfigChanged),
            name: .screenConfigChanged,
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(handleScreenTemporaryStateChanged),
            name: .screenTemporaryStateChanged,
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(handleUserDefaultChanged),
            name: .userDefaultChanged,
            object: nil
        )
    }
    
    @objc private func handlePlaybackDidEnd(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        
        playerItem.seek(to: CMTime.zero) { [weak self] _ in
            self?.applyPlaybackSettings()
        }
    }
    
    @objc private func handleScreenConfigChanged(notification: Notification) {
        guard let screenId = notification.object as? String,
              screenId == playScreen?.identifier,
              let config = ScreenManager.shared.getScreenConfiguration(screenId: screenId) else { return }
        
        screenConfiguration = config
        applyPlaybackSettings()
    }
    
    @objc private func handleScreenTemporaryStateChanged(notification: Notification) {
        if let screenId = notification.userInfo?["screenId"] as? String{
            if screenId == playScreen?.identifier{
                Logger.error("Screen \(screenId) tem status: \(screenTemporaryPause), seektozero: \(screenSeekToZero) ")
                screenTemporaryPause = notification.userInfo?["temporaryPause"] as? Bool ?? false
                screenSeekToZero = notification.userInfo?["seekToZero"] as? Bool ?? false
                applyPlaybackSettings()
            } else if screenId == "All" {
                globalTemporaryPause = notification.userInfo?["temporaryPause"] as? Bool ?? false
                globalSeekToZero = notification.userInfo?["seekToZero"] as? Bool ?? false
                Logger.error("All screens tem status: \(globalTemporaryPause), seektozero: \(globalSeekToZero)")
                applyPlaybackSettings()
            }
        }
    }
    
    @objc private func handleUserDefaultChanged(notification: Notification) {
        applyPlaybackSettings()
    }
    
    func releaseResources() {
        Logger.info("Release video playback view resources. Screen: \(playScreen?.identifier ?? "unknown")")
        
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}
