//
//  SystemModel.swift
//  CodeLume
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
    // 自定义Equatable实现，仅比较id属性
    static func == (lhs: ScreenConfiguration, rhs: ScreenConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
    var id: String
    // 非持久化属性：实时信息，不存储在数据库中
    var isMainScreen: Bool = false
    var isConnected: Bool = false
    
    // 持久化属性：需要存储在数据库中的配置信息
    var playbackType: PlaybackType
    var contentUrl: URL? = nil
    var isPlaying: Bool = true
    var isMuted: Bool = false
    var volume: Double = 0.3
    var videoFillMode: WallpaperFillMode = .fill

    init(
        id: String, 
        playbackType: PlaybackType = .video, 
        contentUrl: URL? = getDefaultBundleURL(),
        isPlaying: Bool = true,
        isMuted: Bool = false,
        volume: Double = 0.3,
        videoFillMode: WallpaperFillMode = .fill
    ) {
        self.id = id
        // 实时信息不设置默认值，由ScreenManager实时计算
        self.playbackType = playbackType
        self.contentUrl = contentUrl
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.volume = volume
        self.videoFillMode = videoFillMode
    }
    
    // 重写CodingKeys，排除非持久化属性
    enum CodingKeys: String, CodingKey {
        case id
        case playbackType
        case contentUrl
        case isPlaying
        case isMuted
        case volume
        case videoFillMode
        // 不包含isMainScreen和isConnected，它们是非持久化的
    }
}
