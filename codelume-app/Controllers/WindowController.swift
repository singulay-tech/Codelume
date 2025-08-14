import Foundation
import AppKit

class WindowController: NSObject {
    var windows: [String: NSWindow] = [:]
    var screenConfigurations: [String: ScreenConfiguration] = [:]
    var playbackViews: [String: NSView] = [:]
    
    override init() {
        super.init()
        // 初始化数据库管理器
        _ = DatabaseManger.shared
        loadConfigurations()
        createWindowsForAllScreens()
        startMonitoringNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: .playVideoUrlChanged, object: nil)
        
        for window in windows.values {
            window.close()
        }
    }
    
    private func createWindowsForAllScreens() {
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
        
        for screen in NSScreen.screens {
            createWindowForScreen(screen)
        }
    }
    
    // MARK: - Configuration Management
    private func createDefaultConfig(for screen: NSScreen) -> ScreenConfiguration {
        let isMainScreen = NSScreen.screens.first?.identifier == screen.identifier
        return ScreenConfiguration(screen: screen, playbackType: .video, contentUrl: nil, isMainScreen: true)
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

        if !configs.isEmpty {
            for config in configs {
                screenConfigurations[config.screenIdentifier] = config
            }
            Logger.info("Configurations loaded from database successfully")
        } else {
            // 如果数据库中没有配置，为每个屏幕创建默认配置
            createDefaultConfigForAllScreens()
        }
        syncScreenConfigurations()
    }

    private func syncScreenConfigurations() {
        // 获取当前所有屏幕的标识符
        let currentScreenIds = NSScreen.screens.map { $0.identifier }

        // 添加新屏幕的配置
        for screen in NSScreen.screens {
            let screenId = screen.identifier
            if !screenConfigurations.keys.contains(screenId) {
                let newConfig = createDefaultConfig(for: screen)
                screenConfigurations[screenId] = newConfig
                DatabaseManger.shared.saveScreenConfig(newConfig)
            }
        }

        // 移除不存在屏幕的配置
        let removedScreenIds = screenConfigurations.keys.filter { !currentScreenIds.contains($0) }
        for screenId in removedScreenIds {
            screenConfigurations.removeValue(forKey: screenId)
            DatabaseManger.shared.deleteScreenConfig(for: screenId)
        }
    }

    // 为所有屏幕创建默认配置
    private func createDefaultConfigForAllScreens() {
        for screen in NSScreen.screens {
            let config = createDefaultConfig(for: screen)
            screenConfigurations[config.screenIdentifier] = config
            DatabaseManger.shared.saveScreenConfig(config)
        }
        Logger.info("Created default configurations for all screens")
    }
    
    func createPlaybackView(for screen: NSScreen) -> NSView? {
        let screenIdentifier = screen.identifier
        let config = screenConfigurations[screenIdentifier] ?? ScreenConfiguration(screen: screen)
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
        let currentScreens = NSScreen.screens
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
            screenConfigurations[screenIdentifier] = ScreenConfiguration(screen: screen, playbackType: playbackType, contentUrl: contentUrl)
        }
        
        saveConfigurations()
        
        if let window = windows[screen.identifier] {
            if let oldView = playbackViews[screenIdentifier] {
                oldView.removeFromSuperview()
            }
            
            let newView = createPlaybackView(for: screen)
            playbackViews[screenIdentifier] = newView
            window.contentView = newView
            window.setIsVisible(true)
        }
    }
    
    func createWindowForScreen(_ screen: NSScreen) {
        Logger.info("Create window for screen: \(screen.identifier)")
        let screenFrame = screen.frame
        let screenIdentifier = screen.identifier
        var isVisible = true
        
        let contentView = NSView(frame: screenFrame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.cgColor
        
        guard let playbackView = createPlaybackView(for: screen) else {
            Logger.error("Create playback view failed.")
            isVisible = false
            return
        }
        
        playbackViews[screenIdentifier] = playbackView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        playbackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playbackView)
        NSLayoutConstraint.activate([
            playbackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playbackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playbackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playbackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .utilityWindow],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.setFrameOrigin(screenFrame.origin)
        window.contentView = contentView
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = true
        window.ignoresMouseEvents = true
        window.orderFront(nil)
        window.setIsVisible(isVisible)
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
    }
    
    @objc private func handleScreenChange(_ notification: Notification) {
        Logger.info("Screen change detected")
        syncScreenConfigurations()
        removeWindowsForRemovedScreens()
        createWindowsForNewScreens()
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
            // 更新现有窗口布局
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
            for screen in NSScreen.screens {
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
