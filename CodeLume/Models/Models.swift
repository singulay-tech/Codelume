//
//  Models.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/28.
//
import Foundation

enum Language: String, CaseIterable {
    case system = "Follow system"
    case chinese = "Chinese"
    case english = "English"
}

enum Theme: String, CaseIterable {
    case system = "Follow system"
    case light = "Light"
    case dark = "Dark"
}

enum PasswordStrength: String {
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
}

struct ScreenConfiguration: Codable, Hashable, Identifiable, Equatable {
    var id: String
    
    var isMainScreen: Bool = false
    var isConnected: Bool = false
    var resolution: String = ""
    
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
