import Foundation
import SQLite
import AppKit

// MARK: - 数据库管理类
final class DatabaseManger {
    static let shared = DatabaseManger()
    private var db: Connection?
    private let dbFileName = "codelume.sqlite3"
    
    private init() {
        openDatabase()
        createLocalBundleTable()
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
    
    // MARK: - 本地屏幕数据
    private let localScreenConfigTable = Table("local_screen_config_table")
    private let screenIdExp = Expression<String>("screenId")
    private let playbackTypeExp = Expression<String>("playbackType")
    private let contentUrlExp = Expression<String?>("contentUrl")
    private let isPlayingExp = Expression<Bool>("isPlaying")
    private let isMuteExp = Expression<Bool>("isMute")
    private let volumeExp = Expression<Double>("volume")
    private let videoFillModeExp = Expression<String>("videoFillMode")
    
    func setScreenConfig(_ config: ScreenConfiguration) {
        guard let db = db else { return }
        do {
            let existingConfig = localScreenConfigTable.filter(screenIdExp == config.id)
            let count = try db.scalar(existingConfig.count)
            if count > 0 {
                let update = existingConfig.update(
                    playbackTypeExp <- config.playbackType.rawValue,
                    contentUrlExp <- config.contentUrl?.path,
                    isPlayingExp <- config.isPlaying,
                    isMuteExp <- config.isMuted,
                    volumeExp <- config.volume,
                    videoFillModeExp <- config.videoFillMode.rawValue
                )
                try db.run(update)
                Logger.info("Updated screen config for: \(config.id)")
            } else {
                let insert = localScreenConfigTable.insert(
                    screenIdExp <- config.id,
                    playbackTypeExp <- config.playbackType.rawValue,
                    contentUrlExp <- config.contentUrl?.path,
                    isPlayingExp <- config.isPlaying,
                    isMuteExp <- config.isMuted,
                    volumeExp <- config.volume,
                    videoFillModeExp <- config.videoFillMode.rawValue
                )
                try db.run(insert)
                Logger.info("Inserted screen config for: \(config.id)")
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
                let videoFillMode = WallpaperFillMode(rawValue: row[videoFillModeExp]) ?? .fill
                return ScreenConfiguration(
                    id: screenId,
                    playbackType: playbackType,
                    contentUrl: contentUrl,
                    isPlaying: row[isPlayingExp],
                    isMuted: row[isMuteExp],
                    volume: row[volumeExp],
                    videoFillMode: videoFillMode
                )
            }
        } catch {
            Logger.error("Failed to get screen config: \(error)")
        }
        return nil
    }
    
    func isUrlInScreenConfig(url: URL) -> Bool {
        guard let db = db else { return false }
        do {
            let query = localScreenConfigTable.filter(contentUrlExp == url.path)
            let count = try db.scalar(query.count)
            return count > 0
        } catch {
            Logger.error("Failed to check if url is in screen config: \(error)")
            return false
        }
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
    
    func getAllScreenConfigs() -> [ScreenConfiguration] {
        guard let db = db else { return [] }
        var configs: [ScreenConfiguration] = []
        do {
            let rows = try db.prepare(localScreenConfigTable)
            for row in rows {
                let screenId = row[screenIdExp]
                let playbackType = PlaybackType(rawValue: row[playbackTypeExp]) ?? .video
                let contentUrl = row[contentUrlExp].flatMap { URL(fileURLWithPath: $0) }
                let videoFillMode = WallpaperFillMode(rawValue: row[videoFillModeExp]) ?? .fill
                let config = ScreenConfiguration(
                    id: screenId,
                    playbackType: playbackType,
                    contentUrl: contentUrl,
                    isPlaying: row[isPlayingExp],
                    isMuted: row[isMuteExp],
                    volume: row[volumeExp],
                    videoFillMode: videoFillMode
                )
                configs.append(config)
            }
        } catch {
            Logger.error("Failed to get all screen configs: \(error)")
        }
        return configs
    }
    
    private func createLocalScreenConfigTable() {
        guard let db = db else { return }
        do {
            try db.run(localScreenConfigTable.create(ifNotExists: true) { tab in
                tab.column(screenIdExp, primaryKey: true)
                tab.column(playbackTypeExp)
                tab.column(contentUrlExp)
                tab.column(isPlayingExp)
                tab.column(isMuteExp)
                tab.column(volumeExp)
                tab.column(videoFillModeExp)
                Logger.info("Create screen config table successfully.")
            })
        } catch {
            Logger.error("Failed to create screen config table: \(error)")
        }
    }
    
    // MARK: - 本地 Bundle 数据
    private let localBundleTable = Table("local_bundle_table")
    private let fileNameExp = Expression<String>("fileName")
    
    private func createLocalBundleTable() {
        guard let db = db else { return }
        do {
            try db.run(localBundleTable.create(ifNotExists: true){ tab in
                tab.column(fileNameExp, primaryKey: true)
                Logger.info("Create local bundle table successfully.")
            })
        } catch {
            Logger.error("Failed to create local bundle table: \(error)")
        }
    }
    
    func addBundle(_ fileName: String) {
        guard let db = db else { return }
        
        do {
            let query = localBundleTable.filter(fileNameExp == fileName)
            let count = try db.scalar(query.count)
            
            if count > 0 {
                Logger.warning("Bundle already exists in database: \(fileName)")
                return
            }
            
            let insert = localBundleTable.insert(
                fileNameExp <- fileName,
            )
            
            try db.run(insert)
            Logger.info("Bundle added successfully: \(fileName)")
            
        } catch {
            Logger.error("Failed to insert local bundle: \(error)")
        }
    }

    func getAllLocalBundles() -> [String] {
        guard let db = db else { return [] }
        var bundles: [String] = []
        do {
            let rows = try db.prepare(localBundleTable)
            for row in rows {
                let bundle = row[fileNameExp]
                bundles.append(bundle)
            }
        } catch {
            Logger.error("Failed to fetch local bundles: \(error)")
        }
        return bundles
    }
    
    func deleteLocalBundle(by fileName: String) {
        guard let db = db else { return }
        let bundle = localBundleTable.filter(fileNameExp == fileName)
        do {
            if let row = try db.pluck(bundle) {
                let file = row[fileNameExp]
                deleteBundleFile(at: file)
            }
            try db.run(bundle.delete())
            Logger.info("Deleted local bundle: \(fileName)")
        } catch {
            Logger.error("Failed to delete local bundle: \(error)")
        }
    }
}
