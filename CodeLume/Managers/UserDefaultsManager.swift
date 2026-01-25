//
//  UserDefaultsManager.swift
//  Codelume
//
//  Created by 广子俞 on 2025/12/11.
//

import Foundation

// MARK: - UserDefaultsManager
class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let userDefaults = UserDefaults.standard
    private init() {}
    
// MARK: - 日志配置
    // MARK: - public
    func saveLogDirectoryPath(_ path: String) {
        userDefaults.set(path, forKey: LogKeys.directoryPath)
    }
    
    func getLogDirectoryPath() -> String {
        if let savedPath = userDefaults.string(forKey: LogKeys.directoryPath) {
            return savedPath
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
    }
    
    func saveLogMaxFileSize(_ size: Int) {
        userDefaults.set(size, forKey: LogKeys.maxFileSize)
    }
    
    func getLogMaxFileSize() -> Int {
        if userDefaults.object(forKey: LogKeys.maxFileSize) != nil {
            return userDefaults.integer(forKey: LogKeys.maxFileSize)
        }
        return LogDefaults.maxFileSize
    }

    func saveLogMaxFileCount(_ count: Int) {
        userDefaults.set(count, forKey: LogKeys.maxFileCount)
    }
    
    func getLogMaxFileCount() -> Int {
        if userDefaults.object(forKey: LogKeys.maxFileCount) != nil {
            return userDefaults.integer(forKey: LogKeys.maxFileCount)
        }
        return LogDefaults.maxFileCount
    }
    
    func clearLogConfig() {
        userDefaults.removeObject(forKey: LogKeys.directoryPath)
        userDefaults.removeObject(forKey: LogKeys.maxFileSize)
        userDefaults.removeObject(forKey: LogKeys.maxFileCount)
    }
    // MARK: - private
    private struct LogKeys {
        static let directoryPath = LOG_DIRECTORY_PATH
        static let maxFileSize = LOG_MAX_FILE_SIZE
        static let maxFileCount = LOG_MAX_FILE_COUNT
        
    }
    
    private struct LogDefaults {
        static let maxFileSize: Int = 5 * 1024 * 1024
        static let maxFileCount: Int = 1
    }
    
// MARK: - 主题配置
    // MARK: - public
    func saveTheme(_ theme: Theme) {
        userDefaults.set(theme.rawValue, forKey: themeKey)
    }
    
    func getTheme() -> Theme {
        if let theme = userDefaults.object(forKey: themeKey) as? String {
            return Theme(rawValue: theme) ?? .system
        }
        return .system
    }

    func clearThemeConfig() {
        userDefaults.removeObject(forKey: themeKey)
    }
    // MARK: - private
    private let themeKey = THEME

// MARK: - 开机自启配置
    // MARK: - public
    func saveStartAtLogin(_ startAtLogin: Bool) {
        userDefaults.set(startAtLogin, forKey: startAtLoginKey)
    }
    
    func getStartAtLogin() -> Bool {
        if userDefaults.object(forKey: startAtLoginKey) != nil {
            return userDefaults.bool(forKey: startAtLoginKey)
        }
        return false
    }
    
    func clearStartAtLoginConfig() {
        userDefaults.removeObject(forKey: startAtLoginKey)
    }
    // MARK: - private
    private let startAtLoginKey = START_AT_LOGIN

// MARK: - 语言配置
    // MARK: - public
    func saveLanguage(_ language: Language) {
        userDefaults.set(language.rawValue, forKey: showLanguageKey)
        Logger.info("save language: \(language.rawValue)")
        switch language {
        case .system:
            userDefaults.removeObject(forKey: languageKey)
        case .chinese:
            userDefaults.set(["zh-Hans-CN"], forKey: languageKey)
        case .english:
            userDefaults.set(["en"], forKey: languageKey)
        }
    }
    
    func getLanguage() -> Language {
        if let language = userDefaults.object(forKey: showLanguageKey) as? String {
            return Language(rawValue: language) ?? .system
        }
        return .system
    }
    
    func clearLanguageConfig() {
        userDefaults.removeObject(forKey: languageKey)
        userDefaults.removeObject(forKey: showLanguageKey)
    }
    // MARK: - private
    private let languageKey = APP_LANGUAGE
    private let showLanguageKey = "showLanguage"

// MARK: - 欢迎配置
    // MARK: - public
    func saveWelcomeStatus(_ welcomeStatus: Bool) {
        userDefaults.set(welcomeStatus, forKey: welcomeStatusKey)
    }
    
    func getWelcomeStatus() -> Bool {
        if userDefaults.object(forKey: welcomeStatusKey) != nil {
            return userDefaults.bool(forKey: welcomeStatusKey)
        }
        return true
    }
    
    func clearWelcomeStatusConfig() {
        userDefaults.removeObject(forKey: welcomeStatusKey)
    }
    // MARK: - private
    private let welcomeStatusKey = WELCOME_STATUS

// MARK: - 播放配置
    // MARK: - public
    func setPauseStatus(_ pause: Bool) {
        userDefaults.set(pause, forKey: pauseKey)
    }

    func getPauseStatus() -> Bool {
        if userDefaults.object(forKey: pauseKey) != nil {
            return userDefaults.bool(forKey: pauseKey)
        }
        return PlaybackDefaults.pause
    }

    func setMuteStatus(_ mute: Bool) {
        userDefaults.set(mute, forKey: muteKey)
    }
    
    func getMuteStatus() -> Bool {
        if userDefaults.object(forKey: muteKey) != nil {
            return userDefaults.bool(forKey: muteKey)
        }
        return PlaybackDefaults.mute
    }
    
    func setVolume(_ volume: Float) {
        userDefaults.set(volume, forKey: volumeKey)
    }
    
    func getVolume() -> Float {
        if userDefaults.object(forKey: volumeKey) != nil {
            return userDefaults.float(forKey: volumeKey)
        }
        return PlaybackDefaults.volume
    }

    func setPauseIfOtherAppOnDesktopStatus(_ pause: Bool) {
        userDefaults.set(pause, forKey: pauseIfOtherAppOnDesktopKey)
    }
    
    func getPauseIfOtherAppOnDesktopStatus() -> Bool {
        if userDefaults.object(forKey: pauseIfOtherAppOnDesktopKey) != nil {
            return userDefaults.bool(forKey: pauseIfOtherAppOnDesktopKey)
        }
        return PlaybackDefaults.pauseIfOtherAppOnDesktop
    }
    
    func setPauseIfOtherAppFullScreenStatus(_ pause: Bool) {
        userDefaults.set(pause, forKey: pauseIfOtherAppFullScreenKey)
    }
    
    func getPauseIfOtherAppFullScreenStatus() -> Bool {
        if userDefaults.object(forKey: pauseIfOtherAppFullScreenKey) != nil {
            return userDefaults.bool(forKey: pauseIfOtherAppFullScreenKey)
        }
        return PlaybackDefaults.pauseIfOtherAppFullScreen
    }

    func setPauseIfBatteryPoweredStatus(_ pause: Bool) {
        userDefaults.set(pause, forKey: pauseIfBatteryPoweredKey)
    }
    
    func getPauseIfBatteryPoweredStatus() -> Bool {
        if userDefaults.object(forKey: pauseIfBatteryPoweredKey) != nil {
            return userDefaults.bool(forKey: pauseIfBatteryPoweredKey)
        }
        return PlaybackDefaults.pauseIfBatteryPowered
    }

    func setPauseIfPowerSavingStatus(_ pause: Bool) {
        userDefaults.set(pause, forKey: pauseIfPowerSavingKey)
    }
    
    func getPauseIfPowerSavingStatus() -> Bool {
        if userDefaults.object(forKey: pauseIfPowerSavingKey) != nil {
            return userDefaults.bool(forKey: pauseIfPowerSavingKey)
        }
        return PlaybackDefaults.pauseIfPowerSaving
    }

    func setSwitchIntervalStatus(_ switchInterval: PlayingSwitchInterval) {
        userDefaults.set(switchInterval.rawValue, forKey: switchIntervalKey)
    }
    
    func getSwitchIntervalStatus() -> PlayingSwitchInterval {
        if userDefaults.object(forKey: switchIntervalKey) != nil {
            return PlayingSwitchInterval(rawValue: userDefaults.string(forKey: switchIntervalKey) ?? PlayingSwitchInterval.oneDay.rawValue) ?? .oneDay
        }
        return PlaybackDefaults.switchInterval
    }

    // MARK: - private
    private let pauseKey = PAUSE
    private let muteKey = MUTE
    private let volumeKey = VOLUME
    private let pauseIfOtherAppOnDesktopKey = PAUSE_IF_OTHER_APP_ON_DESKTOP
    private let pauseIfOtherAppFullScreenKey = PAUSE_IF_OTHER_APP_FULL_SCREEN
    private let pauseIfBatteryPoweredKey = PAUSE_IF_BATTERY_POWERED
    private let pauseIfPowerSavingKey = PAUSE_IF_POWER_SAVING
    private let switchIntervalKey = WALLPAPER_SWITCH_INTERVAL

    private struct PlaybackDefaults {
        static let pause: Bool = false
        static let mute: Bool = true
        static let volume: Float = 0.5
        static let pauseIfOtherAppOnDesktop: Bool = false
        static let pauseIfOtherAppFullScreen: Bool = true
        static let pauseIfBatteryPowered: Bool = false
        static let pauseIfPowerSaving: Bool = true
        static let switchInterval: PlayingSwitchInterval = .oneDay
    }
}
