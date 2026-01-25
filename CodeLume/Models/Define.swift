//
//  Define.swift
//  Codelume
//
//  Created by 广子俞 on 2025/12/18.
//

import Foundation

// MARK: - 动态壁纸保存路径
let WALLPAPER_SAVE_URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Wallpapers")

/// UserDefaults
let PAUSE = "Pause" // 暂停
let MUTE = "Mute" // 静音
let VOLUME = "Volume" // 音量
let PAUSE_IF_OTHER_APP_ON_DESKTOP = "PauseIfOtherAppOnDesktop" // 其他应用在桌面时暂停播放
let PAUSE_IF_OTHER_APP_FULL_SCREEN = "PauseIfOtherAppFullScreen" // 其他应用全屏时暂停播放
let PAUSE_IF_BATTERY_POWERED = "PauseIfBatteryPowered" // 电池供电时暂停播放
let PAUSE_IF_POWER_SAVING = "PauseIfPowerSaving" // 节能模式时暂停播放
let WALLPAPER_SWITCH_INTERVAL = "SwitchInterval" // 壁纸切换间隔
let WELCOME_STATUS = "WelcomeStatus" // 欢迎状态
let APP_LANGUAGE = "AppleLanguages" // 应用语言
let START_AT_LOGIN = "StartAtLogin" // 开机自启配置
let LOG_DIRECTORY_PATH = "LogDirectoryPath" // 日志目录路径
let LOG_MAX_FILE_SIZE = "LogMaxFileSize" // 日志最大文件大小
let LOG_MAX_FILE_COUNT = "LogMaxFileCount" // 日志最大文件数量
let THEME = "Theme" // 主题配置
