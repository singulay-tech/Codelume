import Foundation
import AppKit

class WindowController: NSObject {
    var screens: [NSScreen] = []
    var windows: [String: NSWindow] = [:]
    var screenConfigurations: [String: ScreenConfiguration] = [:]
    var playbackViews: [String: NSView] = [:]
    private var lastScreenChangeTime: TimeInterval = 0
    private let screenChangeDebounceInterval: TimeInterval = 1
    
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
        for screen in screens {
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
        screens = NSScreen.screens

        for config in configs {
            screenConfigurations[config.screenIdentifier] = config
        }

        for screen in screens {
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
            if !setFirstFrameAsWallpaper(videoURL: contentUrl, screenLocalName: screen.identifier) { return nil }
            return VideoPlaybackView(frame: viewFrame, config: config, screen: screen)
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
            setFirstFrameAsWallpaper(videoURL: contentUrl, screenLocalName: screen.identifier)
        }
        
        if !screens.contains(where: { $0.identifier == screen.identifier }) {
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
            Logger.debug("Update screen window: \(screen.identifier)")
            
            // 先释放旧视图的资源
            if let oldView = playbackViews[screenIdentifier] {
                // 检查旧视图是否为VideoPlaybackView类型并调用releaseResources方法
                if let videoPlaybackView = oldView as? VideoPlaybackView {
                    videoPlaybackView.releaseResources()
                }
                // 从窗口内容视图中移除旧视图
                if let contentView = window.contentView {
                    contentView.subviews.forEach { $0.removeFromSuperview() }
                }
            }
            
            // 创建新视图
            if let newView = createPlaybackView(for: screen) {
                playbackViews[screenIdentifier] = newView
                
                // 如果窗口没有contentView，创建一个新的
                if window.contentView == nil {
                    let contentView = NSView(frame: screen.frame)
                    contentView.translatesAutoresizingMaskIntoConstraints = false
                    window.contentView = contentView
                }
                
                // 将新视图添加到contentView并设置自动布局约束（与createWindowForScreen保持一致）
                if let contentView = window.contentView {
                    newView.translatesAutoresizingMaskIntoConstraints = false
                    contentView.addSubview(newView)
                    
                    // 添加约束使播放视图始终填充整个contentView
                    NSLayoutConstraint.activate([
                        newView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                        newView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                        newView.topAnchor.constraint(equalTo: contentView.topAnchor),
                        newView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                    ])
                }
                
                window.setFrame(screen.frame, display: true, animate: true)
            }
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
        
        // 使用自动布局管理contentView
        let contentView = NSView(frame: screenFrame)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView
        
        // 将播放视图添加到contentView并设置自动布局约束
        playbackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playbackView)
        
        // 添加约束使播放视图始终填充整个contentView
        NSLayoutConstraint.activate([
            playbackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playbackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playbackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playbackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = true
        window.ignoresMouseEvents = true
        window.orderFront(nil)
        window.setIsVisible(false)
        // window.delegate = self
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
        let now = Date.timeIntervalSinceReferenceDate
        if now - lastScreenChangeTime < screenChangeDebounceInterval {
            Logger.info("Screen change ignored due to debounce")
            return
        }
        lastScreenChangeTime = now
        let currentScreens = NSScreen.screens
        if currentScreens.count == screens.count {
            screens = currentScreens
            for screen in screens {
                if let window = windows[screen.identifier] {
                    let screenFrame = screen.frame
                    Logger.info("Screen size: \(screenFrame.size)")
                    window.contentAspectRatio = .zero
                    window.setFrameOrigin(screenFrame.origin)
                    window.setFrame(screenFrame, display: true, animate: true)
                }
            }
        } else if currentScreens.count > screens.count {
            let newScreens = currentScreens.filter { !screens.contains($0) }
            Logger.debug("New screens: \(newScreens)")
            screens = currentScreens
            for screen in newScreens {
                if windows[screen.identifier] == nil {
                    createWindowForScreen(screen)
                } else {
                    if let config = screenConfigurations[screen.identifier] {
                        updateScreenConfiguration(screen, playbackType: config.playbackType, contentUrl: config.contentUrl)
                    }
                }
            }
        } else if currentScreens.count < screens.count {
            // 获取移除的屏幕列表
            let removedScreens = screens.filter { !currentScreens.contains($0) }
            screens = currentScreens
            for screen in removedScreens {
                // 检查是否有对应的窗口存在，存在则移除
                if let window = windows[screen.identifier] {
                    // 移除对应的视图
                    if let playbackView = playbackViews[screen.identifier] {
                        playbackView.removeFromSuperview()
                        if let config = screenConfigurations[screen.identifier] {
                            switch config.playbackType {
                            case .video:
                                if let videoPlaybackView = playbackView as? VideoPlaybackView {
                                    videoPlaybackView.releaseResources()
                                }
                                break
                            case .sprite:
                                break
                            case .scene:
                                break
                            default: break
                                
                            }
                        }
                    }
                    playbackViews.removeValue(forKey: screen.identifier)
                    window.setIsVisible(false)
                }
            }
        } else {

        }
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
    
    @objc func handleVideoUrlChange(_ notification: Notification) {
        if let userInfo = notification.userInfo, let videoURL = userInfo["videoURL"] as? URL {
            Logger.info("Received video URL change notification: \(videoURL)")
            
            // 检查是否指定了屏幕ID
            if let screenIdentifier = userInfo["screenIdentifier"] as? String {
                Logger.info("Targeting specific screen: \(screenIdentifier)")
                
                // 查找对应的屏幕
                if let targetScreen = screens.first(where: { $0.identifier == screenIdentifier }) {
                    // 只更新指定屏幕的配置
                    updateScreenConfiguration(targetScreen, playbackType: .video, contentUrl: videoURL)
                } else {
                    Logger.warning("Screen not found for identifier: \(screenIdentifier)")
                }
            } else {
                // 如果没有指定屏幕ID，则更新所有屏幕
                for screen in screens {
                    updateScreenConfiguration(screen, playbackType: .video, contentUrl: videoURL)
                }
            }
        }
    }
}
