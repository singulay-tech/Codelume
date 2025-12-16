//
//  VideoPlaybackView.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/12.
//

import AppKit
import AVKit
import AVFoundation

class VideoPlaybackView: NSView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playScreen: NSScreen?
    private var screenConfiguration: ScreenConfiguration?
    
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
            // Load video configuration from JSON files
            let videoUrl = try loadVideoUrl(from: bundleUrl)
            
            // Initialize player and layer
            player = AVPlayer(url: videoUrl)
            setupPlayerLayer()
            
            // Apply initial playback settings
            applyPlaybackSettings()
            
            // Start monitoring notifications
            setupNotificationObservers()
            
            // Post visibility notification and start playback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Logger.info("Post visibility notification and start playback after delay for screen: \(self.screenConfiguration?.id)")
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
    
    // MARK: - Video Loading
    private func loadVideoUrl(from bundleUrl: URL) throws -> URL {
        // Load main configuration
        let codelumeJsonUrl = bundleUrl.appendingPathComponent("codelume.json")
        let codelumeJsonData = try Data(contentsOf: codelumeJsonUrl)
        let codelumeJson = try JSONSerialization.jsonObject(with: codelumeJsonData) as? [String: Any]
        
        guard let videoJsonPath = codelumeJson?["video"] as? String else {
            throw NSError(domain: "VideoPlaybackView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing video field in codelume.json"])
        }
        
        // Load video details
        let videoJsonUrl = bundleUrl.appendingPathComponent(videoJsonPath)
        let videoJsonData = try Data(contentsOf: videoJsonUrl)
        let videoJson = try JSONSerialization.jsonObject(with: videoJsonData) as? [String: Any]
        
        guard let videoPath = videoJson?["url"] as? String else {
            throw NSError(domain: "VideoPlaybackView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing url field in video.json"])
        }
        
        return bundleUrl.appendingPathComponent(videoPath)
    }
    
    // MARK: - Playback Settings
    private func applyPlaybackSettings() {
        guard let player = player, let config = screenConfiguration else { return }
        
        // Volume control: global * screen level
        let globalVolume = UserDefaultsManager.shared.getVolume()
        let screenVolume = Float(config.volume)
        Logger.info("Screen: \(config.id), volume: \(globalVolume * screenVolume)")
        player.volume = globalVolume * screenVolume
        
        // Mute control: global takes precedence
        let globalMute = UserDefaultsManager.shared.getMuteStatus()
        player.isMuted = globalMute || config.isMuted
        Logger.info("Screen: \(config.id), mute: \(player.isMuted)")
        
        // Playback control: global pause takes precedence
        let globalPause = UserDefaultsManager.shared.getPauseStatus()
        let shouldPlay = !globalPause && config.isPlaying
        Logger.info("Screen: \(config.id), play: \(shouldPlay)")
        
        if shouldPlay {
            player.play()
        } else {
            player.pause()
        }
    }
    
    // MARK: - Notification Handling
    private func setupNotificationObservers() {
        let center = NotificationCenter.default
        
        // Video playback finished
        center.addObserver(
            self,
            selector: #selector(handlePlaybackDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        // Screen configuration changed
        center.addObserver(
            self,
            selector: #selector(handleScreenConfigChanged),
            name: .screenConfigChanged,
            object: nil
        )
        
        // Global playback state changed
        center.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: .playbackStateChanged,
            object: nil
        )
        
        // Seek to zero
        center.addObserver(
            self,
            selector: #selector(handleSeekToZero),
            name: .seekToZero,
            object: nil
        )
    }
    
    @objc private func handlePlaybackDidEnd(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        
        playerItem.seek(to: CMTime.zero) { [weak self] _ in
            self?.applyPlaybackSettings()
        }
    }
    
    @objc private func handleSeekToZero(notification: Notification) {
        if playScreen?.identifier != notification.object as? String { return }
        guard let player = player else { return }
        
        player.seek(to: CMTime.zero) { [weak self] _ in
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
    
    @objc private func handlePlaybackStateChanged(notification: Notification) {
        applyPlaybackSettings()
    }
    
    // MARK: - Resource Management
    func releaseResources() {
        Logger.info("Release video playback view resources. Screen: \(playScreen?.identifier ?? "unknown")")
        
        // Remove all observers
        NotificationCenter.default.removeObserver(self)
        
        // Pause and release player resources
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}
