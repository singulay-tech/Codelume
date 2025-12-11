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
        UserDefaults.standard.synchronize()
        if userDefaults.object(forKey: LogKeys.maxFileSize) != nil {
            return userDefaults.integer(forKey: LogKeys.maxFileSize)
        }
        return LogDefaults.maxFileSize
    }

    func saveLogMaxFileCount(_ count: Int) {
        userDefaults.set(count, forKey: LogKeys.maxFileCount)
    }
    
    func getLogMaxFileCount() -> Int {
        UserDefaults.standard.synchronize()
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
}
