import AppKit
import Foundation
import CodelumeBundle

// MARK: - 屏幕管理类
class ScreenManager: ObservableObject {
    static let shared = ScreenManager()
    @Published var screenConfigurations: [ScreenConfiguration] = []
    @Published var currentScreens: [NSScreen] = []
    private let databaseManager = DatabaseManger.shared
    private var timer: Timer? // 定时器，用来周期性检测屏幕配置，做出响应的响应
    private var screenLock: Bool = false
    private var temporaryPause: Bool = false {
        didSet {
            if oldValue != temporaryPause {
                NotificationCenter.default.post(name: .screenTemporaryStateChanged, object: nil, userInfo: ["screenId": "All", "temporaryPause": temporaryPause, "seekToZero": seekToZero])
                Logger.info("Screen temporary state changed to: \(temporaryPause), seekToZero: \(seekToZero)")
            }
        }
    }
    private var seekToZero: Bool = false // 是否需要跳转到第一帧
    private var screenTemporaryPause: [String: Bool] = [:] // 每个屏幕的临时暂停状态
    
    private init() {
        updateCurrentScreens()
        loadScreenConfigurations()
        handleScreenChanges()
        updateMainScreenFlag()
        sortScreenConfigurations()
        startTimer()
        startNotificationMonitor()
    }
    
    deinit {
        stopTimer()
        stopNotificationMonitor()
    }
    
    /// 启动通知监控
    func startNotificationMonitor() {
        // 监听屏幕参数变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        DistributedNotificationCenter.default.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { _ in
            self.screenLock = true
        }
        
        DistributedNotificationCenter.default.addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { _ in
            self.screenLock = false
        }
    }
    
    /// 停止通知监控
    func stopNotificationMonitor() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateCurrentScreens() {
        currentScreens = NSScreen.screens
    }
    
    private func handleScreenChanges() {
        let currentScreenIdentifiers = Set(currentScreens.map { $0.identifier })
        let configuredScreenIdentifiers = Set(screenConfigurations.map { $0.id })
        
        // 处理已断开连接的屏幕
        let removedScreenIdentifiers = configuredScreenIdentifiers.subtracting(currentScreenIdentifiers)
        for screenId in removedScreenIdentifiers {
            if let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) {
                var updatedConfig = screenConfigurations[index]
                updatedConfig.isConnected = false
                updatedConfig.isMainScreen = false
                screenConfigurations[index] = updatedConfig
                Logger.info("screen \(screenId) disconnected")
            }
        }
        
        // 新增屏幕配置
        let addedScreenIdentifiers = currentScreenIdentifiers.subtracting(configuredScreenIdentifiers)
        for screenId in addedScreenIdentifiers {
            if screenId == "" { continue }
            guard let screen = currentScreens.first(where: { $0.identifier == screenId }) else { continue }
            let newConfig = createDefaultScreenConfiguration(screen: screen)
            
            screenConfigurations.append(newConfig)
            // 新增的屏幕需要存储到数据库
            databaseManager.setScreenConfig(newConfig)
            Logger.info("screen \(screenId) added")
        }
        
        // 处理重新连接的屏幕
        let reconnectedScreenIdentifiers = currentScreenIdentifiers.intersection(configuredScreenIdentifiers)
        for screenId in reconnectedScreenIdentifiers {
            if let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) {
                var updatedConfig = screenConfigurations[index]
                if !updatedConfig.isConnected {
                    updatedConfig.isConnected = true
                    updatedConfig.isPlaying = databaseManager.getScreenConfig(for: screenId)?.isPlaying ?? false
                    screenConfigurations[index] = updatedConfig
                    Logger.info("screen \(screenId) reconnected")
                }
            }
        }
    }
    
    // 更新主屏幕标记
    private func updateMainScreenFlag() {
        screenConfigurations.enumerated().forEach { index, config in
            let matchingScreen = currentScreens.first { screen in
                screen.identifier == config.id
            }
            
            let isMainScreen = matchingScreen?.isMain ?? false
            
            if config.isMainScreen != isMainScreen {
                var updatedConfig = config
                updatedConfig.isMainScreen = isMainScreen
                screenConfigurations[index] = updatedConfig
            }
        }
    }
    
    private func createDefaultScreenConfiguration(screen: NSScreen) -> ScreenConfiguration {
        let screenId = screen.identifier
        let screenResolution = getPhysicalScreenResolution(screen: screen)
        Logger.info("create default screen: \(screenId), physical resolution: \(screenResolution)")
        
        let config = ScreenConfiguration(
            id: screenId,
            playbackType: .video,
            wallpaperUrl: getDefaultWallpaperURL(),
            isPlaying: true,
            isMuted: false,
            volume: 0.3,
            fillMode: .fill,
            physicalResolution: screenResolution
        )
        return config
    }
    
    private func loadScreenConfigurations() {
        let savedConfigs = databaseManager.getAllScreenConfigs()
        screenConfigurations = savedConfigs
        Logger.info("load \(savedConfigs.count) screen configurations from database")
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
        return "\(width) x \(height)"
    }
    
    func getPhysicalScreenResolution(screen: NSScreen) -> String {
        let screenFrame = screen.frame
        let backingScaleFactor = screen.backingScaleFactor
        let physicalWidth = Int(screenFrame.width * backingScaleFactor)
        let physicalHeight = Int(screenFrame.height * backingScaleFactor)
        return "\(physicalWidth) x \(physicalHeight)"
    }
    
    func getCurrentScreenCount() -> Int {
        return currentScreens.count
    }
    
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
    
    func updateMuteStatus(screenId: String, status: Bool) {
        guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { return }
        
        var updatedConfig = screenConfigurations[index]
        updatedConfig.isMuted = status
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
    }
    
    // 更新屏幕内容URL
    func updateScreenWallpaper(screenId: String, wallpaperURL: URL?) {
        guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { return }
        
        var updatedConfig = screenConfigurations[index]
        updatedConfig.wallpaperUrl = wallpaperURL
        
        let bundle = BaseBundle()
        bundle.open(wallpaperUrl: wallpaperURL!)
        Logger.info("type \(bundle.bundleInfo.type)")
        switch bundle.bundleInfo.type {
        case .video:
            updatedConfig.playbackType = .video
        case .Scene2D:
            updatedConfig.playbackType = .sprite
        case .Scene3D:
            updatedConfig.playbackType = .scene
            
        default:
            updatedConfig.playbackType = .video
        }
        //        updatedConfig.playbackType =  wallpaper.wallpaperInfo.type
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
        
        Logger.info("更新屏幕壁纸URL: \(screenId) -> \(wallpaperURL?.path ?? "nil")")
    }
    
    func updateAllScreensWallpaper(wallpaperURL: URL) {
        for screen in screenConfigurations {
            updateScreenWallpaper(screenId: screen.id, wallpaperURL: wallpaperURL)
        }
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
        updatedConfig.fillMode = fillMode
        
        screenConfigurations[index] = updatedConfig
        databaseManager.setScreenConfig(updatedConfig)
        
        Logger.info("更新屏幕视频填充模式: \(screenId) -> \(fillMode.rawValue)")
    }
    
    // MARK: - 屏幕配置重置
    // 重置所有屏幕配置
    func resetAllScreenConfigurations() {
        
        for config in screenConfigurations {
            databaseManager.deleteScreenConfig(for: config.id)
        }
        
        screenConfigurations.removeAll()
        
        for screen in NSScreen.screens {
            let newConfig = createDefaultScreenConfiguration(screen: screen)
            screenConfigurations.append(newConfig)
            databaseManager.setScreenConfig(newConfig)
        }
        
        Logger.info("reset all screen configurations")
        updateMainScreenFlag()
        sortScreenConfigurations()
    }
    
    // 重置特定屏幕配置
    func resetScreenConfiguration(screenId: String) {
        guard let screen = NSScreen.screens.first(where: { $0.identifier == screenId }) else { return }
        
        let newConfig = createDefaultScreenConfiguration(screen: screen)
        
        if let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) {
            screenConfigurations[index] = newConfig
        } else {
            screenConfigurations.append(newConfig)
        }
        
        databaseManager.setScreenConfig(newConfig)
        updateMainScreenFlag()
        Logger.info("Reset Screen Config: \(screenId)")
    }
    
    // 删除特定屏幕配置
    func deleteScreenConfiguration(screenId: String) {
        screenConfigurations.removeAll { $0.id == screenId }
        databaseManager.deleteScreenConfig(for: screenId)
        Logger.info("Delete Screen Config: \(screenId)")
    }
    
    func getScreenConfiguration(screenId: String) -> ScreenConfiguration? {
        return screenConfigurations.first(where: { $0.id == screenId })
    }
    
    /// 处理屏幕参数变化通知
    @objc private func screensParametersDidChange() {
        Logger.info("screen configurations changed")
        updateCurrentScreens()
        handleScreenChanges()
        updateMainScreenFlag()
        sortScreenConfigurations()
    }
    
    // MARK: - 定时器，周期性检查屏幕的一些状态
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkStatus), userInfo: nil, repeats: true)
        checkStatus()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func checkStatus() {
        checkScreens()
        checkTheGlobalPlaybackState()
    }
    
    private func checkScreens() {
        let screens = NSScreen.screens
        let pauseIfOtherAppOnDesktop = UserDefaultsManager.shared.getPauseIfOtherAppOnDesktopStatus()
        let pauseIfOtherAppFullScreen = UserDefaultsManager.shared.getPauseIfOtherAppFullScreenStatus()
        
        for screen in screens {
            let screenId = screen.identifier
            guard let index = screenConfigurations.firstIndex(where: { $0.id == screenId }) else { continue }
            
            var temporaryPause = false
            var seekToZero = false
            
            // 检查是否有其他应用在屏幕上
            if pauseIfOtherAppOnDesktop && isOtherAppOnScreen(screen) {
                Logger.debug("Other app detected on screen: \(screenId)")
                temporaryPause = true
                seekToZero = false
            }
            
            // 检查是否有全屏应用
            if pauseIfOtherAppFullScreen && isAnyAppFullScreenOnScreen(screen) {
                Logger.debug("Full screen app detected on screen: \(screenId)")
                temporaryPause = true
                seekToZero = true
            }
            
            // 只有当屏幕状态发生变化时，才发送特定屏幕的播放状态通知
            if screenTemporaryPause[screenId] != temporaryPause {
                NotificationCenter.default.post(name: .screenTemporaryStateChanged, object: nil, userInfo: ["screenId": screenId, "temporaryPause": temporaryPause, "seekToZero": seekToZero])
                screenTemporaryPause[screenId] = temporaryPause
                Logger.info("Screen Temporary State Changed: \(screenId) -> \(temporaryPause), seekToZero: \(seekToZero)")
            }
        }
    }
    
    /// 检查动态壁纸的全局播放状态
    private func checkTheGlobalPlaybackState() {
        if screenLock {
            temporaryPause = true
            seekToZero = true
            return
        }
        
        // 检查电源相关设置
        let pauseIfBatteryPowered = UserDefaultsManager.shared.getPauseIfBatteryPoweredStatus()
        let pauseIfPowerSaving = UserDefaultsManager.shared.getPauseIfPowerSavingStatus()
        
        if pauseIfBatteryPowered && isBatteryPowered() {
            Logger.debug("Pausing playback because device is on battery power")
            temporaryPause = true
            seekToZero = false
            return
        }
        
        if pauseIfPowerSaving && isPowerSavingMode() {
            Logger.debug("Pausing playback because device is in power saving mode")
            temporaryPause = true
            seekToZero = false
            return
        }
        
        temporaryPause = false
        return
    }
}
