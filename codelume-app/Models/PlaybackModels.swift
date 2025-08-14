import AppKit
import Foundation

enum PlaybackType: String, Codable {
    case video
    case sprite
    case scene
}

struct ScreenConfiguration: Codable {
    let screenIdentifier: String
    var isMainScreen: Bool
    var playbackType: PlaybackType
    var contentUrl: URL?
    var volume: Float = 0.0
    var isPlaying: Bool = true
    
    init(screen: NSScreen, playbackType: PlaybackType = .video, contentUrl: URL? = nil, isMainScreen: Bool = true) {
        self.screenIdentifier = screen.identifier
        self.isMainScreen = isMainScreen
        self.playbackType = playbackType
        self.contentUrl = contentUrl
    }
}

struct WallpaperItem: Identifiable {
    let id: UUID
    var title: String
    var filePath: String
    var category: String
    var resolution: String
    var fileSize: Int
    var codec: String
    var duration: Double
    var creationDate: Date
    var tags: [String]
    var isPlaying: Bool = false
}

enum Interval: String, CaseIterable {
    case fiveMinutes = "Five minutes"
    case tenMinutes = "Ten minutes"
    case halfHour = "Half an hour"
    case oneHour = "One hour"
    case oneDay = "One day"
    case oneWeek = "One week"
    case oneMonth = "One month"
}

enum SenceType: Int, CaseIterable {
    case VideoSence = 0
    case SpritekitSence = 1
}
