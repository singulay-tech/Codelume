//
//  LogManager.swift
//  CodeLume
//
//  Created by guangziyu on 2025/3/13.
//

import Foundation
import SwiftyBeaver
// MARK: - 日志管理类
class LogManager {
    static let shared = LogManager()
    let log = SwiftyBeaver.self
    private init() {
        setupLogger()
    }
    // MARK: - public
    func getLogDirectory() -> URL {
        let path = UserDefaultsManager.shared.getLogDirectoryPath()
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    func setLogDirectory(_ url: URL) {
        UserDefaultsManager.shared.saveLogDirectoryPath(url.path)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        setupLogger()
    }
    
    func getMaxFileSize() -> Int {
        return Int(UserDefaultsManager.shared.getLogMaxFileSize())
    }
    
    func setMaxFileSize(_ size: Int) {
        UserDefaultsManager.shared.saveLogMaxFileSize(Int(size))
        setupLogger()
    }
    
    func getMaxFileCount() -> Int {
        return UserDefaultsManager.shared.getLogMaxFileCount()
    }
    
    func setMaxFileCount(_ count: Int) {
        UserDefaultsManager.shared.saveLogMaxFileCount(count)
        setupLogger()
    }
    
    func clearAllLogs() {
        let logDirectory = getLogDirectory()
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)
            
            for file in files {
                let fileName = file.lastPathComponent
                if fileName.starts(with: "codlelume.log") {
                    try fileManager.removeItem(at: file)
                }
            }
            log.info("all log files cleaned")
        } catch {
            log.error("clean log files failed: \(error.localizedDescription)")
        }
    }
    // MARK: - private
    private func setupLogger() {
        let console = ConsoleDestination()
        console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M"
        
        let file = FileDestination()
        let logDirectory = getLogDirectory()
        file.logFileURL = logDirectory.appendingPathComponent("codlelume.log")
        file.logFileMaxSize = getMaxFileSize()
        file.logFileAmount = getMaxFileCount()
        file.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M"
        
        log.removeAllDestinations()
        log.addDestination(console)
        log.addDestination(file)
        
        log.info("log system initialized")
        log.info("log file path: \(file.logFileURL?.path ?? "unknown")")
    }
}
// MARK: - 简化调用 API
enum Logger {
    static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        LogManager.shared.log.verbose(message, file: file, function: function, line: line)
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        LogManager.shared.log.debug(message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        LogManager.shared.log.info(message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        LogManager.shared.log.warning(message, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        LogManager.shared.log.error(message, file: file, function: function, line: line)
    }
}
