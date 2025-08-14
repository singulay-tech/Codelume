import Foundation
import AppKit

class WindowController: NSObject {
    var windows: [NSScreen: NSWindow] = [:]
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
        
        if let window = windows[screen] {
            if let oldView = playbackViews[screenIdentifier] {
                oldView.removeFromSuperview()
            }
            
            let newView = createPlaybackView(for: screen)
            playbackViews[screenIdentifier] = newView
            window.contentView = newView
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
        contentView.addSubview(playbackView)
        
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
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = false
        window.makeKeyAndOrderFront(nil)
        window.setIsVisible(isVisible)
        windows[screen] = window
    }
    
    func startMonitoringNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc func handleScreenChange() {
        createWindowsForAllScreens()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        for window in windows.values {
            window.close()
        }
    }
}