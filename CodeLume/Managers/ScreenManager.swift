import AppKit
import Foundation

// MARK: - 屏幕管理类
class ScreenManager: ObservableObject {
    static let shared = ScreenManager()
    @Published var screenConfigurations: [ScreenConfiguration] = []
    @Published var currentScreens: [NSScreen] = []
    private let databaseManager = DatabaseManger.shared
    
    private init() {
        updateCurrentScreens()
        loadScreenConfigurations()
        handleScreenChanges() // 确保所有当前连接的屏幕都有对应的配置

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screensDidChange() {
        Logger.info("screen configurations changed")
        updateCurrentScreens()
        handleScreenChanges()
    }
    
    private func updateCurrentScreens() {
        currentScreens = NSScreen.screens
    }
    
    private func handleScreenChanges() {
        let currentScreenIdentifiers = Set(currentScreens.map { $0.identifier })
        let configuredScreenIdentifiers = Set(screenConfigurations.map { $0.id })
        
        // Handle removed screens: update connection status instead of deleting
        let removedScreenIdentifiers = configuredScreenIdentifiers.subtracting(currentScreenIdentifiers)
        for screenId in removedScreenIdentifiers {
            if let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) {
                var updatedConfig = screenConfigurations[index]
                updatedConfig.isConnected = false
                screenConfigurations[index] = updatedConfig
                databaseManager.setScreenConfig(updatedConfig)
                Logger.info("屏幕已断开连接: \(screenId)")
            }
        }
        
        // Handle added screens (new or reconnected)
        let addedScreenIdentifiers = currentScreenIdentifiers.subtracting(configuredScreenIdentifiers)
        for screenId in addedScreenIdentifiers {
            guard let screen = currentScreens.first(where: { $0.identifier == screenId }) else { continue }
            
            let isMainScreen = screen == NSScreen.main
            let newConfig = createDefaultScreenConfiguration(screen: screen, isMainScreen: isMainScreen)
            
            screenConfigurations.append(newConfig)
            databaseManager.setScreenConfig(newConfig)
            Logger.info("屏幕已添加: \(screenId)")
        }
        
        // Handle reconnected screens (already in configured screens)
        let reconnectedScreenIdentifiers = currentScreenIdentifiers.intersection(configuredScreenIdentifiers)
        for screenId in reconnectedScreenIdentifiers {
            if let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) {
                var updatedConfig = screenConfigurations[index]
                if !updatedConfig.isConnected {
                    updatedConfig.isConnected = true
                    screenConfigurations[index] = updatedConfig
                    databaseManager.setScreenConfig(updatedConfig)
                    Logger.info("屏幕已重新连接: \(screenId)")
                }
            }
        }
        
        // Update main screen flag for all screens
        updateMainScreenFlag()
        
        // 排序屏幕配置，确保主屏幕在第一位
        sortScreenConfigurations()
    }
    
    // 更新主屏幕标记
    private func updateMainScreenFlag() {
        screenConfigurations.enumerated().forEach { index, config in
            // 只更新已连接屏幕的主屏幕标记
            if config.isConnected {
                // 查找匹配的屏幕
                let matchingScreen = currentScreens.first { screen in
                    screen.identifier == config.id
                }
                
                let isMainScreen = matchingScreen?.isMain ?? false
                
                if config.isMainScreen != isMainScreen {
                    var updatedConfig = config
                    updatedConfig.isMainScreen = isMainScreen
                    screenConfigurations[index] = updatedConfig
                    databaseManager.setScreenConfig(updatedConfig)
                }
            } else {
                // 断开连接的屏幕不能是主屏幕
                if config.isMainScreen {
                    var updatedConfig = config
                    updatedConfig.isMainScreen = false
                    screenConfigurations[index] = updatedConfig
                    databaseManager.setScreenConfig(updatedConfig)
                }
            }
        }
    }
    
    // MARK: - 配置管理
    
    // 创建默认屏幕配置
    private func createDefaultScreenConfiguration(screen: NSScreen, isMainScreen: Bool) -> ScreenConfiguration {
        let screenId = screen.identifier
        let screenResolution = getScreenResolution(screen: screen)
        
        Logger.info("create default screen: \(screenId), resolution: \(screenResolution), is main: \(isMainScreen)")
        
        var config = ScreenConfiguration(
            id: screenId,
            playbackType: .video,
            contentUrl: getDefaultBundleURL(),
            isPlaying: true,
            isMuted: false,
            volume: 0.3,
            videoFillMode: .fill
        )
        
        // 设置主屏幕标记
        config.isMainScreen = isMainScreen
        return config
    }
    
    private func loadScreenConfigurations() {
        let savedConfigs = databaseManager.getAllScreenConfigs()
        screenConfigurations = savedConfigs
        Logger.info("load \(savedConfigs.count) screen configurations from database")
        
        // 加载后实时更新连接状态和主屏幕标记
        updateScreenRealTimeInfo()
    }
    
    private func updateScreenRealTimeInfo() {
        let currentScreenIdentifiers = Set(currentScreens.map { $0.identifier })
        
        // 更新所有屏幕配置的连接状态
        for i in screenConfigurations.indices {
            let isConnected = currentScreenIdentifiers.contains(screenConfigurations[i].id)
            screenConfigurations[i].isConnected = isConnected
            
            // 如果屏幕断开连接，自动取消其主屏幕状态
            if !isConnected {
                screenConfigurations[i].isMainScreen = false
            }
        }
        
        // 更新主屏幕标记（只针对已连接的屏幕）
        updateMainScreenFlag()
        
        // 确保主屏幕被正确识别 - 直接检查当前主屏幕并设置标记
        if let mainScreen = NSScreen.main {
            let mainScreenId = mainScreen.identifier
            for i in screenConfigurations.indices {
                if screenConfigurations[i].id == mainScreenId && screenConfigurations[i].isConnected {
                    if !screenConfigurations[i].isMainScreen {
                        var updatedConfig = screenConfigurations[i]
                        updatedConfig.isMainScreen = true
                        screenConfigurations[i] = updatedConfig
                        Logger.info("已将屏幕 \(mainScreenId) 标记为主屏幕")
                    }
                    // 确保其他屏幕不是主屏幕
                } else if screenConfigurations[i].isMainScreen {
                    var updatedConfig = screenConfigurations[i]
                    updatedConfig.isMainScreen = false
                    screenConfigurations[i] = updatedConfig
                }
            }
        }
        
        // 排序屏幕配置，确保主屏幕在第一位
        sortScreenConfigurations()
    }
    
    private func sortScreenConfigurations() {
        screenConfigurations.sort { config1, config2 in
            // 主屏幕优先
            if config1.isMainScreen && !config2.isMainScreen {
                return true
            } else if !config1.isMainScreen && config2.isMainScreen {
                return false
            }
            
            // 连接状态其次
            if config1.isConnected && !config2.isConnected {
                return true
            } else if !config1.isConnected && config2.isConnected {
                return false
            }
            
            // 最后按ID排序（保持稳定）
            return config1.id < config2.id
        }
        Logger.info("屏幕配置已排序，主屏幕现在位于第一位")
    }
    
    // MARK: - 屏幕信息获取
    
    func getScreenResolution(screen: NSScreen) -> String {
        let screenFrame = screen.frame
        let width = Int(screenFrame.width)
        let height = Int(screenFrame.height)
        return "\(width)x\(height)"    }
    
    func getPhysicalScreenResolution(screen: NSScreen) -> String {
        let screenFrame = screen.frame
        let backingScaleFactor = screen.backingScaleFactor
        let physicalWidth = Int(screenFrame.width * backingScaleFactor)
        let physicalHeight = Int(screenFrame.height * backingScaleFactor)
        return "\(physicalWidth)x\(physicalHeight)"
    }
    
    func getCurrentScreenCount() -> Int {
        return currentScreens.count
    }
    
    func getConfiguration(for screen: NSScreen) -> ScreenConfiguration? {
        return screenConfigurations.first(where: { $0.id == screen.identifier })
    }
    
    func getConfiguration(for screenId: String) -> ScreenConfiguration? {
        return screenConfigurations.first(where: { $0.id == screenId })
    }
    
    // MARK: - 播放状态管理
    
    func updatePlaybackState(screenId: String, isPlaying: Bool) {
        guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { return }
        
        var updatedConfig = screenConfigurations[index]
        updatedConfig.isPlaying = isPlaying
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
        
        Logger.info("更新屏幕播放状态: \(screenId) -> \(isPlaying)")
    }
    
    // 更新屏幕音量
    func updateVolume(screenId: String, volume: Double) {
        guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { return }
        
        var updatedConfig = screenConfigurations[index]
        updatedConfig.volume = max(0.0, min(1.0, volume)) // 限制音量在0-1之间
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
        
        Logger.info("更新屏幕音量: \(screenId) -> \(updatedConfig.volume)")
    }
    
    // 更新屏幕内容URL
    func updateContentUrl(screenId: String, contentUrl: URL?) {
        guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { return }
        
        var updatedConfig = screenConfigurations[index]
        updatedConfig.contentUrl = contentUrl
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
        
        Logger.info("更新屏幕内容URL: \(screenId) -> \(contentUrl?.path ?? "nil")")
    }
    
    // 更新屏幕播放类型
    func updatePlaybackType(screenId: String, playbackType: PlaybackType) {
        guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { return }
        
        var updatedConfig = screenConfigurations[index]
        updatedConfig.playbackType = playbackType
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
        
        Logger.info("更新屏幕播放类型: \(screenId) -> \(playbackType.rawValue)")
    }
    
    // 更新屏幕视频填充模式
    func updateVideoFillMode(screenId: String, fillMode: WallpaperFillMode) {
        guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { return }
        
        var updatedConfig = screenConfigurations[index]
        updatedConfig.videoFillMode = fillMode
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
        
        Logger.info("更新屏幕视频填充模式: \(screenId) -> \(fillMode.rawValue)")
    }
    
    // MARK: - 屏幕配置重置
    
    // 重置所有屏幕配置
    func resetAllScreenConfigurations() {
        // 清除数据库中的配置
        for config in screenConfigurations {
            databaseManager.deleteScreenConfig(for: config.id)
        }
        
        // 重新创建默认配置
        screenConfigurations.removeAll()
        
        for screen in NSScreen.screens {
            let isMainScreen = screen == NSScreen.main
            let newConfig = createDefaultScreenConfiguration(screen: screen, isMainScreen: isMainScreen)
            screenConfigurations.append(newConfig)
            databaseManager.setScreenConfig(newConfig)
        }
        
        Logger.info("已重置所有屏幕配置")
        
        // 排序屏幕配置，确保主屏幕在第一位
        sortScreenConfigurations()
    }
    
    // 重置特定屏幕配置
    func resetScreenConfiguration(screenId: String) {
         guard let screen = NSScreen.screens.first(where: { $0.identifier == screenId }) else { return }
        
        // let isMainScreen = screen == NSScreen.main
        let newConfig = createDefaultScreenConfiguration(screen: screen, isMainScreen: false)
        
        if let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) {
            screenConfigurations[index] = newConfig
        } else {
            screenConfigurations.append(newConfig)
        }
        
        databaseManager.setScreenConfig(newConfig)
        Logger.info("Reset Screen Config: \(screenId)")
    }

    // 删除特定屏幕配置
    func deleteScreenConfiguration(screenId: String) {
        screenConfigurations.removeAll { $0.id == screenId }
        databaseManager.deleteScreenConfig(for: screenId)
        Logger.info("Delete Screen Config: \(screenId)")
    }
}