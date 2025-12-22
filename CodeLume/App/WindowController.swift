import Foundation
import AppKit

class WindowController: NSObject {
    var screens: [NSScreen] = []
    var windows: [String: NSWindow] = [:]
    var screenConfigurations: [String: ScreenConfiguration] = [:]
    var playbackViews: [String: NSView] = [:]
    private var lastScreenChangeTime: TimeInterval = 0
    private let screenChangeDebounceInterval: TimeInterval = 1
    private var mainScreen: String = NSScreen.main?.identifier ?? ""
    
    override init() {
        super.init()
        addDefaultWallpaper()
        startMonitoringNotification()
        screens = NSScreen.screens
        loadConfigurations()
        createWindowsForAllScreens()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        for window in windows.values {
            window.close()
        }
    }
    
    private func createWindowsForAllScreens() {
        for screen in screens {
            createWindowForScreen(screen)
        }
    }
    
    private func loadConfigurations() {
        screenConfigurations = [:]
        let configs = DatabaseManger.shared.getAllScreenConfigs()
        
        for config in configs {
            screenConfigurations[config.id] = config
        }
        
        Logger.info("Configurations loaded successfully")
    }
    
    func createPlaybackView(for screen: NSScreen) -> NSView? {
        let id = screen.identifier
        guard let config = screenConfigurations[id] else {
            Logger.error("Screen configuration not found. Screen: \(id)")
            return nil
        }
        
        let viewFrame = screen.frame
        
        guard let contentUrl = config.wallpaperUrl else {
            Logger.error("Content url is nil. Screen: \(id)")
            return nil
        }
        
        if !FileManager.default.fileExists(atPath: contentUrl.path) {
            Logger.error("File not found at URL: \(contentUrl). Screen: \(id)")
            return nil
        }
        
        switch config.playbackType {
        case .video:
            Logger.info("Create video playback view.")
            if !setStaticWallpaper(bundleURL: contentUrl, screenLocalName: screen.identifier) { return nil }
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
            setStaticWallpaper(bundleURL: contentUrl, screenLocalName: screen.identifier)
        }
        
        if !screens.contains(where: { $0.identifier == screen.identifier }) {
            Logger.info("Screen does not exist, creating new window for it: \(screen.identifier)")
            createWindowForScreen(screen)
        }
        
        let id = screen.identifier
        if var config = screenConfigurations[id] {
            config.playbackType = playbackType
            config.wallpaperUrl = contentUrl
            screenConfigurations[id] = config
        } else {
            screenConfigurations[id] = ScreenConfiguration(id: id, playbackType: playbackType, wallpaperUrl: contentUrl)
        }
        
        
        if let window = windows[screen.identifier] {
            Logger.debug("Update screen window: \(screen.identifier)")
            
            // 先释放旧视图的资源
            if let oldView = playbackViews[id] {
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
                playbackViews[id] = newView
                
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
        let id = screen.identifier
        
        guard let playbackView = createPlaybackView(for: screen) else {
            Logger.error("Create playback view failed.")
            return
        }
        
        playbackViews[id] = playbackView
        
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
            selector: #selector(handleWallpaperBundleChanged),
            name: .wallpaperBundleChanged,
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
        // 主屏幕切换时重启应用
        if mainScreen != NSScreen.main?.identifier ?? "" {
            restartApplication()
        }

        loadConfigurations()
        let currentScreens = NSScreen.screens
        if currentScreens.count == screens.count {            
            Logger.info("Same screens count: \(currentScreens.count)")
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
            Logger.info("New screens count: \(currentScreens.count - screens.count)")
            let newScreens = currentScreens.filter { !screens.contains($0) }
            screens = currentScreens
            for screen in newScreens {
                if windows[screen.identifier] == nil {
                    Logger.info("Create window for new screen: \(screen.identifier)")
                    createWindowForScreen(screen)
                } else {
                    Logger.info("Update window for existing screen: \(screen.identifier)")
                    if let config = screenConfigurations[screen.identifier] {
                        updateScreenConfiguration(screen, playbackType: config.playbackType, contentUrl: config.wallpaperUrl)
                    }
                }
            }
        } else if currentScreens.count < screens.count {
            Logger.info("Removed screens count: \(screens.count - currentScreens.count)")
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
            let id = identifier
            if let window = windows[id] {
                if let isVisible = notification.userInfo?["isVisible"] as? Bool {
                    window.setIsVisible(isVisible)
                }
            }
        }
    }
    
    @objc func handleWallpaperBundleChanged(_ notification: Notification) {
        Logger.info("Received wallpaper bundle changed notification.")
        loadConfigurations()
        if let userInfo = notification.userInfo {
            Logger.info("Received bundle URL change notification.")
            
            // 检查是否指定了屏幕ID
            if let id = userInfo["id"] as? String {
                Logger.info("Targeting specific screen: \(id)")
                
                // 查找对应的屏幕
                if let targetScreen = screens.first(where: { $0.identifier == id }) {
                    // 只更新指定屏幕的配置
                    if let config = screenConfigurations[targetScreen.identifier] {
                        updateScreenConfiguration(targetScreen, playbackType: config.playbackType, contentUrl: config.wallpaperUrl)
                    }
                } else {
                    Logger.warning("Screen not found for identifier: \(id)")
                }
            } else {
                // 如果没有指定屏幕ID，则更新所有屏幕
                Logger.info("Updating configurations for all screens.")
                for screen in screens {
                    if let config = screenConfigurations[screen.identifier] {
                        updateScreenConfiguration(screen, playbackType: config.playbackType, contentUrl: config.wallpaperUrl)
                    }
                }
            }
        }
    }
}
