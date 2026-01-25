//
//  SystemModel.swift
//  Codelume
//
//  Created by 广子俞 on 2025/12/11.
//

import Foundation

// MARK: - 语言
enum Language: String, CaseIterable {
        case system = "Follow system"
        case chinese = "Chinese"
        case english = "English"
}

// MARK: - 主题
enum Theme: String, CaseIterable {
        case system = "Follow system"
        case light = "Light"
        case dark = "Dark"
}

// MARK: - 屏幕配置
struct ScreenConfiguration: Codable, Hashable, Identifiable, Equatable {
    var id: String
    // 非持久化属性：实时信息，不存储在数据库中
    var isMainScreen: Bool = false
    var isConnected: Bool = false
    var resolution: String = ""
    
    // 持久化属性：需要存储在数据库中的配置信息
    var playbackType: PlaybackType
    var wallpaperUrl: URL? = nil
    var isPlaying: Bool = true
    var isMuted: Bool = false
    var volume: Double = 0.3
    var physicalResolution: String = ""
    var fillMode: WallpaperFillMode = .fill

    init(
        id: String, 
        playbackType: PlaybackType = .video, 
        wallpaperUrl: URL? = nil,
        isPlaying: Bool = true,
        isMuted: Bool = false,
        volume: Double = 0.3,
        fillMode: WallpaperFillMode = .fill,
        physicalResolution: String = ""
    ) {
        self.id = id
        self.playbackType = playbackType
        self.wallpaperUrl = wallpaperUrl
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.volume = volume
        self.fillMode = fillMode
        self.physicalResolution = physicalResolution
    }
    
    // 重写CodingKeys，排除非持久化属性
    enum CodingKeys: String, CodingKey {
        case id
        case playbackType
        case wallpaperUrl
        case isPlaying
        case isMuted
        case volume
        case fillMode
        case physicalResolution
    }
}

struct WallpaperTable: Decodable, Identifiable {
    let id: Int
    let fileName: String
    let createdAt: Date
    
    static func == (lhs: WallpaperTable, rhs: WallpaperTable) -> Bool {
        return lhs.id == rhs.id
    }
}
