import Foundation
import AppKit

class WindowController: NSObject {
    var windows: [String: NSWindow] = [:]
    var screenConfigurations: [String: ScreenConfiguration] = [:]
    var playbackViews: [String: NSView] = [:]
    
    override init() {
        super.init()
        loadConfigurations()
        createWindowsForAllScreens()
        startMonitoringNotification()
    }
    
    func createWindowsForAllScreens() {
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
        
        for screen in NSScreen.screens {
            createWindowForScreen(screen)
        }
    }
    
    func createDefaultConfig() {
        let screens = NSScreen.screens
        for (index, screen) in screens.enumerated() {
            let screenIdentifier = screen.identifier
            let isMainScreen = index == 0
            screenConfigurations[screenIdentifier] = ScreenConfiguration(screen: screen, isMainScreen: isMainScreen)
        }
        saveConfigurations()
    }
    
    func syncScreenConfigurations() {
        let currentScreens = NSScreen.screens
        var existingIdentifiers = Set(screenConfigurations.keys)
        
        for screen in currentScreens {
            let screenIdentifier = screen.identifier
            if !existingIdentifiers.contains(screenIdentifier) {
                Logger.info("Found new screen, adding to config: \(screenIdentifier)")
                let isMainScreen = currentScreens.first?.identifier == screenIdentifier
                screenConfigurations[screenIdentifier] = ScreenConfiguration(screen: screen, isMainScreen: isMainScreen)
                saveConfigurations()
            }
            existingIdentifiers.remove(screenIdentifier)
        }
        
        // 不存在的屏幕配置暂时保留，有可能会重新连接上
        // for removedIdentifier in existingIdentifiers {
        //     Logger.info("Screen removed, removing from config: \(removedIdentifier)")
        //     screenConfigurations.removeValue(forKey: removedIdentifier)
        //     saveConfigurations()
        // }
    }
    
    func saveConfigurations() {
        let defaults = UserDefaults.standard
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(screenConfigurations)
            defaults.set(data, forKey: "screenConfigurations")
            Logger.info("Screen configurations saved successfully.")
        } catch {
            Logger.error("Failed to save screen configurations: \(error).")
        }
    }
    
    func loadConfigurations() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "screenConfigurations") {
            do {
                let decoder = JSONDecoder()
                screenConfigurations = try decoder.decode([String: ScreenConfiguration].self, from: data)
            } catch {
                Logger.error("Screen config load error: \(error).")
            }
            Logger.info("Screen config load success.")
            syncScreenConfigurations()
            print(screenConfigurations)
        } else {
            Logger.info("Screen config not found, create default config.")
            createDefaultConfig()
        }
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
    
    @objc func handleScreenChange() {
        Logger.info("Screen change notification received.")
        let currentScreenCount = NSScreen.screens.count
        if currentScreenCount != windows.count {
            Logger.info("Screen count changed from \(windows.count) to \(currentScreenCount), rebuilding windows.")
            createWindowsForAllScreens()
        } else {
            Logger.info("Screen count unchanged (\(currentScreenCount)), updating window layouts.")
            let currentScreens = NSScreen.screens
            let screenMap = [String: NSScreen](uniqueKeysWithValues: currentScreens.map { ($0.identifier, $0) })
            for (screenIdentifier, window) in windows {
                if let screen = screenMap[screenIdentifier] {
                    let screenFrame = screen.frame
                    Logger.info("Updating window frame for screen \(screenIdentifier) from \(window.frame) to \(screenFrame)")
                    window.contentAspectRatio = .zero
                    window.setFrame(screenFrame, display: true, animate: true)
                    if let contentView = window.contentView {
                        contentView.setFrameSize(screenFrame.size)
                        Logger.info("Updated content view size to \(screenFrame.size)")
                    }
                } else {
                    Logger.warning("Screen not found for identifier: \(screenIdentifier)")
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: .playVideoUrlChanged, object: nil)
        for window in windows.values {
            window.close()
        }
    }
}