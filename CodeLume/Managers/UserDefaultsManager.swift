//
//  UserDefaultsManager.swift
//  CodeLume
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
        static let directoryPath = "logDirectoryPath"
        static let maxFileSize = "logMaxFileSize"
        static let maxFileCount = "logMaxFileCount"
    }
    
    private struct LogDefaults {
        static let maxFileSize: Int = 5 * 1024 * 1024
        static let maxFileCount: Int = 1
    }
    
// MARK: - 主题配置
    // MARK: - public
    enum themeType: Int {
        case system = 0
        case light = 1
        case dark = 2
    }
    
    func saveTheme(_ theme: themeType) {
        userDefaults.set(theme.rawValue, forKey: themeKeys)
    }
    
    func getTheme() -> themeType {
        if let theme = userDefaults.object(forKey: themeKeys) as? Int {
            return themeType(rawValue: theme) ?? .system
        }
        return .system
    }

    func clearThemeConfig() {
        userDefaults.removeObject(forKey: themeKeys)
    }
    // MARK: - private
    let themeKeys = "codelumeTheme"

// MARK: - 开机自启配置
    // MARK: - public
    func saveStartAtLogin(_ startAtLogin: Bool) {
        userDefaults.set(startAtLogin, forKey: startAtLoginKeys)
    }
    
    func getStartAtLogin() -> Bool {
        if userDefaults.object(forKey: startAtLoginKeys) != nil {
            return userDefaults.bool(forKey: startAtLoginKeys)
        }
        return false
    }
    
    func clearStartAtLoginConfig() {
        userDefaults.removeObject(forKey: startAtLoginKeys)
    }
    // MARK: - private
    let startAtLoginKeys = "startAtLogin"

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
    let languageKey = "AppleLanguages"
    let showLanguageKey = "showLanguage"
}
