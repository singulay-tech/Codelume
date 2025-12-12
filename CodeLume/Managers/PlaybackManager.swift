import Foundation
import AppKit

// MARK: - 播放管理类
class PlaybackManager {
    static let shared = PlaybackManager()
    
    // 全局播放状态
    private var isPlaying: Bool = true {
        didSet {
            if oldValue != isPlaying {
                Logger.info("Global playback state changed to: \(isPlaying)")
                NotificationCenter.default.post(name: .playbackStateChanged, 
                                              object: nil, 
                                              userInfo: ["isPlaying": isPlaying, "seekToZero": seekToZero])
            }
        }
    }
    
    // 每个屏幕的播放状态
    private var screenPlaybackStates: [String: Bool] = [:]
    private var seekToZero = false
    private var timer: Timer?
    private var screenLock = false
    
    private init() {
        Logger.info("PlaybackManager initialized")
        // 注册UserDefaults默认值，确保首次安装时就能正确读取
        let defaults: [String: Any] = [
            "pauseIfOtherAppOnDesktop": false,
            "pauseIfOtherAppFullScreen": true,
            "pauseIfBatteryPowered": false,
            "pauseIfPowerSaving": true
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    func start() {
        Logger.info("PlaybackManager started")
        registerScreenLockNotification()
        startTimer()
    }

    func stop() {
        Logger.info("PlaybackManager stopped")
        stopTimer()
        unregisterScreenLockNotification()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkStatus), userInfo: nil, repeats: true)
        checkStatus()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func registerScreenLockNotification() {
        DistributedNotificationCenter.default.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { _ in
            self.screenLock = true
            self.updatePlaybackState()
        }
        
        DistributedNotificationCenter.default.addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { _ in
            self.screenLock = false
            self.updatePlaybackState()
        }
    }
    
    private func unregisterScreenLockNotification() {
        DistributedNotificationCenter.default.removeObserver(self, name: .init("com.apple.screenIsLocked"), object: nil)
        DistributedNotificationCenter.default.removeObserver(self, name: .init("com.apple.screenIsUnlocked"), object: nil)
    }
    
    @objc private func checkStatus() {
        checkPowerStatus()
        checkScreens()
        updatePlaybackState()
    }
    
    private func checkPowerStatus() {
        // 电源状态检查已经合并到updatePlaybackState中
    }
    
    private func checkScreens() {
        let screens = NSScreen.screens
        let pauseIfOtherAppOnDesktop = UserDefaults.standard.bool(forKey: "pauseIfOtherAppOnDesktop")
        let pauseIfOtherAppFullScreen = UserDefaults.standard.bool(forKey: "pauseIfOtherAppFullScreen")
        
        // 存储新的屏幕状态
        var newScreenPlaybackStates: [String: Bool] = [:]
        
        for screen in screens {
            let screenId = screen.identifier
            let screenName = screen.localizedName
            
            // 默认情况下屏幕允许播放
            var shouldScreenPlay = true
            
            // 检查是否有其他应用在屏幕上
            if pauseIfOtherAppOnDesktop && isOtherAppOnScreen(screen) {
                Logger.debug("Other app detected on screen: \(screenName)")
                shouldScreenPlay = false
                seekToZero = false
            }
            
            // 检查是否有全屏应用
            if pauseIfOtherAppFullScreen && isAnyAppFullScreenOnScreen(screen) {
                Logger.debug("Full screen app detected on screen: \(screenName)")
                shouldScreenPlay = false
                seekToZero = true
            }
            
            // 只有当屏幕状态发生变化时，才发送特定屏幕的播放状态通知
            if screenPlaybackStates[screenId] != shouldScreenPlay {
                newScreenPlaybackStates[screenId] = shouldScreenPlay
                Logger.info("Screen \(screenName) playback state changed to: \(shouldScreenPlay)")
                
                // 发送屏幕特定的播放状态通知
                NotificationCenter.default.post(name: .screenPlayStateChanged,
                                              object: screenId,
                                              userInfo: ["screenName": screenName, "isPlaying": shouldScreenPlay, "seekToZero": seekToZero])
            }
        }
        
        // 更新屏幕播放状态字典
        screenPlaybackStates.merge(newScreenPlaybackStates) { _, new in new }
        
        // 移除已不存在屏幕的状态记录
        let currentScreenIds = Set(screens.map { $0.identifier })
        let removedScreenIds = screenPlaybackStates.keys.filter { !currentScreenIds.contains($0) }
        for screenId in removedScreenIds {
            screenPlaybackStates.removeValue(forKey: screenId)
        }
    }
    
    // 根据所有条件更新全局播放状态
    private func updatePlaybackState() {
        // 如果屏幕锁定，全局暂停
        if screenLock {
            isPlaying = false
            seekToZero = true
            return
        }
        
        // 检查电源相关设置
        let pauseIfBatteryPowered = UserDefaults.standard.bool(forKey: "pauseIfBatteryPowered")
        let pauseIfPowerSaving = UserDefaults.standard.bool(forKey: "pauseIfPowerSaving")
        
        if pauseIfBatteryPowered && isBatteryPowered() {
            Logger.debug("Pausing playback because device is on battery power")
            isPlaying = false
            seekToZero = true
            return
        }
        
        if pauseIfPowerSaving && isPowerSavingMode() {
            Logger.debug("Pausing playback because device is in power saving mode")
            isPlaying = false
            seekToZero = true
            return
        }
        
        // 全局播放状态不再依赖于屏幕状态，只要没有其他暂停条件就保持开启
        isPlaying = true
        return
    }
}
