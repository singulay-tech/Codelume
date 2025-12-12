import AppKit
import Foundation

enum PlaybackType: String, Codable {
    case video
    case sprite
    case scene
    
    var description: String {
        return self.rawValue
    }
}

enum WallpaperFillMode: String, Codable, CaseIterable {
    case fit = "Fit"
    case fill = "Fill"
    case stretch = "Stretch"

    var description: String {
        return self.rawValue
    }
}

struct WallpaperItem: Identifiable {
    let id: UUID
    var title: String
    var fileUrl: URL
    var resolution: String
    var fileSize: Int
    var codec: String
    var duration: Double
    var creationDate: Date
    var isPlaying: Bool = false
}

enum PlayingSwitchInterval: String, CaseIterable {
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
