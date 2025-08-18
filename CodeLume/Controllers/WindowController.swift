import Foundation
import AppKit

class WindowController: NSObject {
    var currentScreens: [NSScreen] = []
    var windows: [String: NSWindow] = [:]
    var screenConfigurations: [String: ScreenConfiguration] = [:]
    var playbackViews: [String: NSView] = [:]
    
    override init() {
        super.init()
        addDefaultVideo()
        startMonitoringNotification()
        loadConfigurations()
        createWindowsForAllScreens()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: .playVideoUrlChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .setWallpaperIsVisible, object: nil)
        
        for window in windows.values {
            window.close()
        }
    }
    
    private func createWindowsForAllScreens() {
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
        
        for screen in currentScreens {
            createWindowForScreen(screen)
        }
    }
    
    private func createDefaultConfig(for screen: NSScreen) -> ScreenConfiguration {
        return ScreenConfiguration(screenIdentifier: screen.identifier)
    }

    private func saveConfigurations() {
        for (_, config) in screenConfigurations {
            DatabaseManger.shared.saveScreenConfig(config)
        }
        Logger.info("Configurations saved to database successfully")
    }

    private func loadConfigurations() {
        screenConfigurations = [:] 
        let configs = DatabaseManger.shared.getAllScreenConfigs()
        currentScreens = NSScreen.screens

        for config in configs {
            screenConfigurations[config.screenIdentifier] = config
        }

        for screen in currentScreens {
            let screenId = screen.identifier
            if screenConfigurations[screenId] == nil {
                let newConfig = createDefaultConfig(for: screen)
                screenConfigurations[screenId] = newConfig
                DatabaseManger.shared.saveScreenConfig(newConfig)
            }
        }

        Logger.info("Configurations loaded successfully")
    }
    
    func createPlaybackView(for screen: NSScreen) -> NSView? {
        let screenIdentifier = screen.identifier
        guard let config = screenConfigurations[screenIdentifier] else {
            Logger.error("Screen configuration not found. Screen: \(screenIdentifier)")
            return nil
        }

        let viewFrame = screen.frame

        guard let contentUrl = config.contentUrl else {
            Logger.error("Content url is nil. Screen: \(screenIdentifier)")
            return nil
        }

        if !FileManager.default.fileExists(atPath: contentUrl.path) {
            Logger.error("File not found at URL: \(contentUrl). Screen: \(screenIdentifier)")
            return nil
        }
        
        switch config.playbackType {
        case .video:
            Logger.info("Create video playback view.")
            if !setFirstFrameAsWallpaper(videoURL: contentUrl) { return nil }
            return VideoPlaybackView(frame: viewFrame, config: config)
        case .sprite:
            Logger.info("Create sprite playback view.")
            return SpriteKitPlaybackView(frame: viewFrame)
        case .scene:
            Logger.info("Create scene playback view.")
            return SceneKitPlaybackView(frame: viewFrame)
        }
    }
    
    func updateScreenConfiguration(_ screen: NSScreen, playbackType: PlaybackType, contentUrl: URL? = nil) {
        NotificationCenter.default.post(name: .setWallpaperIsVisible, object: screen.identifier, userInfo: ["isVisible": false])

        if let contentUrl = contentUrl {
            setFirstFrameAsWallpaper(videoURL: contentUrl)
        }
        
        if !currentScreens.contains(where: { $0.identifier == screen.identifier }) {
            Logger.info("Screen does not exist, creating new window for it: \(screen.identifier)")
            createWindowForScreen(screen)
        }
        
        let screenIdentifier = screen.identifier
        if var config = screenConfigurations[screenIdentifier] {
            config.playbackType = playbackType
            config.contentUrl = contentUrl
            screenConfigurations[screenIdentifier] = config
        } else {
            screenConfigurations[screenIdentifier] = ScreenConfiguration(screenIdentifier: screenIdentifier, playbackType: playbackType, contentUrl: contentUrl)
        }
        
        saveConfigurations()
        
        if let window = windows[screen.identifier] {            
            let newView = createPlaybackView(for: screen)
            playbackViews[screenIdentifier] = newView
            window.contentView = newView
        }
    }
    
    func createWindowForScreen(_ screen: NSScreen) {
        Logger.info("Create window for screen: \(screen.identifier)")
        let screenFrame = screen.frame
        let screenIdentifier = screen.identifier
        
        guard let playbackView = createPlaybackView(for: screen) else {
            Logger.error("Create playback view failed.")
            return
        }
        
        playbackViews[screenIdentifier] = playbackView
        
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .utilityWindow],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.setFrameOrigin(screenFrame.origin)
        window.contentView = playbackView
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = true
        window.ignoresMouseEvents = true
        window.orderFront(nil)
        window.setIsVisible(false)
        windows[screen.identifier] = window
    }
    
    func startMonitoringNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVideoUrlChange),
            name: .playVideoUrlChanged,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWallpaperIsVisibleChange),
            name: .setWallpaperIsVisible,
            object: nil)
    }
    
    @objc private func handleScreenChange(_ notification: Notification) {
        Logger.info("Screen change detected")
        removeWindowsForRemovedScreens()
        createWindowsForNewScreens()
    }

    @objc private func handleWallpaperIsVisibleChange(_ notification: Notification) {
        if let identifier = notification.object as? String {
            let screenIdentifier = identifier
            if let window = windows[screenIdentifier] {
                if let isVisible = notification.userInfo?["isVisible"] as? Bool {
                    window.setIsVisible(isVisible)
                }
            }
        }
    }

    private func createWindowsForNewScreens() {
        let currentScreens = NSScreen.screens
        let currentScreenIds = Set(currentScreens.map { $0.identifier })
        let existingWindowIds = Set(windows.keys)
        let newScreenIds = currentScreenIds.subtracting(existingWindowIds)

        if !newScreenIds.isEmpty {
            Logger.info("Found \(newScreenIds.count) new screens, creating windows")
            for screen in currentScreens {
                if newScreenIds.contains(screen.identifier) {
                    createWindowForScreen(screen)
                }
            }
        } else {
            Logger.info("Updating layouts for all existing windows")
            let screenMap = [String: NSScreen](uniqueKeysWithValues: currentScreens.map { ($0.identifier, $0) })
            for (screenIdentifier, window) in windows {
                if let screen = screenMap[screenIdentifier] {
                    let screenFrame = screen.frame
                    window.contentAspectRatio = .zero
                    window.setFrame(screenFrame, display: true, animate: true)
                    if let contentView = window.contentView {
                        contentView.setFrameSize(screenFrame.size)
                    }
                }
            }
        }
    }
    
    @objc func handleVideoUrlChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let videoURL = userInfo["videoURL"] as? URL {
            Logger.info("Received video URL change notification: \(videoURL)")
            for screen in currentScreens {
                updateScreenConfiguration(screen, playbackType: .video, contentUrl: videoURL)
            }
        }
    }
    
    func removeWindowsForRemovedScreens() {
        let currentScreens = NSScreen.screens
        let currentScreenIdentifiers = Set(currentScreens.map { $0.identifier })
        let removedIdentifiers = Set(windows.keys).subtracting(currentScreenIdentifiers)
        
        for removedIdentifier in removedIdentifiers {
            Logger.info("Screen removed, cleaning up resources for: \(removedIdentifier)")
            if let window = windows[removedIdentifier] {
                window.close()
                windows.removeValue(forKey: removedIdentifier)
            }
            playbackViews.removeValue(forKey: removedIdentifier)
        }
    }
    
    
}
