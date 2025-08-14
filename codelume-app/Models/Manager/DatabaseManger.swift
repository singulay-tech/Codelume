import Foundation
import SQLite
import AppKit

final class DatabaseManger {
    static let shared = DatabaseManger()
    
    private var db: Connection?
    private let dbFileName = "codelume.sqlite3"
    
    private let localVideoTable = Table("local_video_table")
    private let uuidExp = Expression<String>("uuid")
    private let titleExp = Expression<String>("title")
    private let auther = Expression<String>("auther")
    private let describe = Expression<String>("describe")
    private let fileUrlExp = Expression<URL>("fileUrl")
    private let resolutionExp = Expression<String>("resolution")
    private let fileSizeExp = Expression<Int>("fileSize")
    private let codecExp = Expression<String>("codec")
    private let durationExp = Expression<Double>("duration")
    private let creationDateExp = Expression<Date>("creationDate")
    
    private let localScreenConfigTable = Table("local_screen_config_table")
    private let screenIdExp = Expression<String>("screenId")
    private let isMainScreenExp = Expression<Bool>("isMainScreen")
    private let playbackTypeExp = Expression<String>("playbackType")
    private let contentUrlExp = Expression<String?>("contentUrl")
    private let isPlayingExp = Expression<Bool>("isPlaying")
    private let videoFillModeExp = Expression<String>("videoFillMode")
    
    private let localSpriteTable = Table("local_sprite_table")
    private let locatSceneTable = Table("local_secene_table")
    
    private init() {
        openDatabase()
        createLocalVideoTable()
        createLocalScreenConfigTable()
        
    }
    
    private func openDatabase() {
        do {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbURL = docDir.appendingPathComponent(dbFileName)
            db = try Connection(dbURL.path)
            Logger.info("Database opened at: \(dbURL.path)")
        } catch {
            Logger.error("Failed to open database: \(error)")
        }
    }
    
    private func createLocalVideoTable() {
        guard let db = db else { return }
        do {
            try db.run(localVideoTable.create(ifNotExists: true){ tab in
                tab.column(uuidExp, primaryKey: true)
                tab.column(titleExp)
                tab.column(fileUrlExp, unique: true)
                tab.column(resolutionExp)
                tab.column(fileSizeExp)
                tab.column(codecExp)
                tab.column(durationExp)
                tab.column(creationDateExp)
                Logger.info("Create play list table successfully.")
            })
        } catch {
            Logger.error("Failed to create local video table: \(error)")
        }
    }
    
    private func createLocalScreenConfigTable() {
        guard let db = db else { return }
        do {
            try db.run(localScreenConfigTable.create(ifNotExists: true) { tab in
                tab.column(screenIdExp, primaryKey: true)
                tab.column(isMainScreenExp)
                tab.column(playbackTypeExp)
                tab.column(contentUrlExp)
                tab.column(isPlayingExp)
                tab.column(videoFillModeExp)
                Logger.info("Create screen config table successfully.")
            })
        } catch {
            Logger.error("Failed to create screen config table: \(error)")
        }
    }
    
    func saveScreenConfig(_ config: ScreenConfiguration) {
        guard let db = db else { return }
        do {
            let existingConfig = localScreenConfigTable.filter(screenIdExp == config.screenIdentifier)
            let count = try db.scalar(existingConfig.count)
            if count > 0 {
                let update = existingConfig.update(
                    isMainScreenExp <- config.isMainScreen,
                    playbackTypeExp <- config.playbackType.rawValue,
                    contentUrlExp <- config.contentUrl?.path,
                    isPlayingExp <- config.isPlaying,
                    videoFillModeExp <- config.videoFillMode.rawValue
                )
                try db.run(update)
                Logger.info("Updated screen config for: \(config.screenIdentifier)")
            } else {
                let insert = localScreenConfigTable.insert(
                    screenIdExp <- config.screenIdentifier,
                    isMainScreenExp <- config.isMainScreen,
                    playbackTypeExp <- config.playbackType.rawValue,
                    contentUrlExp <- config.contentUrl?.path,
                    isPlayingExp <- config.isPlaying,
                    videoFillModeExp <- config.videoFillMode.rawValue
                )
                try db.run(insert)
                Logger.info("Inserted screen config for: \(config.screenIdentifier)")
            }
        } catch {
            Logger.error("Failed to save screen config: \(error)")
        }
    }
    
    func getScreenConfig(for screenId: String) -> ScreenConfiguration? {
        guard let db = db else { return nil }
        do {
            let query = localScreenConfigTable.filter(screenIdExp == screenId)
            if let row = try db.pluck(query) {
                let playbackType = PlaybackType(rawValue: row[playbackTypeExp]) ?? .video
                let contentUrl = row[contentUrlExp].flatMap { URL(fileURLWithPath: $0) }
                let videoFillMode = VideoFillMode(rawValue: row[videoFillModeExp]) ?? .fill
                let currentScreen = NSScreen.screens.first { $0.localizedName == screenId } ?? nil
                guard let screen = currentScreen else {
                    return nil
                }
                return ScreenConfiguration(
                    screen: screen,
                    playbackType: playbackType,
                    contentUrl: contentUrl,
                    isMainScreen: row[isMainScreenExp],
                    videoFillMode: videoFillMode
                )
            }
        } catch {
            Logger.error("Failed to get screen config: \(error)")
        }
        return nil
    }
    
    func getAllScreenConfigs() -> [ScreenConfiguration] {
        guard let db = db else { return [] }
        var configs: [ScreenConfiguration] = []
        do {
            let rows = try db.prepare(localScreenConfigTable)
            for row in rows {
                let screenId = row[screenIdExp]
                let playbackType = PlaybackType(rawValue: row[playbackTypeExp]) ?? .video
                let contentUrl = row[contentUrlExp].flatMap { URL(fileURLWithPath: $0) }
                let videoFillMode = VideoFillMode(rawValue: row[videoFillModeExp]) ?? .fill
                let currentScreen = NSScreen.screens.first { $0.identifier == screenId } ?? nil
                guard let screen = currentScreen else {
                    continue
                }
                let config = ScreenConfiguration(
                    screen: screen,
                    playbackType: playbackType,
                    contentUrl: contentUrl,
                    isMainScreen: row[isMainScreenExp],
                    videoFillMode: videoFillMode
                )
                configs.append(config)
            }
        } catch {
            Logger.error("Failed to get all screen configs: \(error)")
        }
        return configs
    }
    
    func deleteScreenConfig(for screenId: String) {
        guard let db = db else { return }
        do {
            let config = localScreenConfigTable.filter(screenIdExp == screenId)
            try db.run(config.delete())
            Logger.info("Deleted screen config for: \(screenId)")
        } catch {
            Logger.error("Failed to delete screen config: \(error)")
        }
    }
    
    func addLocalVideo(_ video: WallpaperItem) {
        guard fileExists(at: video.fileUrl) else {
            Logger.error("File does not exist at url: \(video.fileUrl), not adding to database.")
            return
        }
        guard let db = db else { return }
        let insert = localVideoTable.insert(
            uuidExp <- video.id.uuidString,
            titleExp <- video.title,
            fileUrlExp <- video.fileUrl,
            resolutionExp <- video.resolution,
            fileSizeExp <- video.fileSize,
            codecExp <- video.codec,
            durationExp <- video.duration,
            creationDateExp <- video.creationDate,
        )
        
        do { try db.run(insert) } catch {
            Logger.error("Failed to insert local video: \(error)")
        }
    }

    func getAllLocalVideos() -> [WallpaperItem] {
        guard let db = db else { return [] }
        var videos: [WallpaperItem] = []
        do {
            let rows = try db.prepare(localVideoTable)
            for row in rows {
                let video = WallpaperItem(
                    id: UUID(uuidString: row[uuidExp])!,
                    title: row[titleExp],
                    fileUrl: row[fileUrlExp],
                    resolution: row[resolutionExp],
                    fileSize: row[fileSizeExp],
                    codec: row[codecExp],
                    duration: row[durationExp],
                    creationDate: row[creationDateExp]
                )
                videos.append(video)
            }
        } catch {
            Logger.error("Failed to fetch local videos: \(error)")
        }
        return videos
    }
    
    func deleteLocalVideo(by uuid: UUID) {
        guard let db = db else { return }
        let video = localVideoTable.filter(uuidExp == uuid.uuidString)
        do {
            if let row = try db.pluck(video) {
                let fileUrl = row[fileUrlExp]
                deleteFile(at: fileUrl)
            }
            try db.run(video.delete())
            Logger.info("Deleted local video: \(uuid)")
        } catch {
            Logger.error("Failed to delete local video: \(error)")
        }
    }
    
    func deleteLocalVideo(byFileUrl fileUrl: URL) {
        guard let db = db else { return }
        let video = localVideoTable.filter(fileUrlExp == fileUrl)
        do {
            deleteFile(at: fileUrl)
            try db.run(video.delete())
            Logger.info("Deleted local video: \(fileUrl)")
        } catch {
            Logger.error("Failed to delete local video: \(error)")
        }
    }
    
    func deleteLocalVideo(item: WallpaperItem) {
        deleteLocalVideo(by: item.id)
    }
    
    func printAllLocalWallpapers() {
        guard let db = db else { return }
        do {
            let rows = try db.prepare(localVideoTable)
            Logger.info("---- Local Wallpapers ----")
            for row in rows {
                Logger.info("uuid: \(row[uuidExp]), title: \(row[titleExp]), fileUrl: \(row[fileUrlExp]), resolution: \(row[resolutionExp]), fileSize: \(row[fileSizeExp]), codec: \(row[codecExp]), duration: \(row[durationExp]), creationDate: \(row[creationDateExp])")
            }
        } catch {
            Logger.error("Failed to fetch local wallpapers: \(error)")
        }
    }
}
