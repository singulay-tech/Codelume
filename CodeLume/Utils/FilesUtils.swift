import AVFoundation
import AppKit
import Foundation
import ServiceManagement
import UniformTypeIdentifiers

func getVideoSaveURL() -> URL? {
    let fileManager = FileManager.default
    guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    
    let videosSaveURL = docDir.appendingPathComponent("Videos")
    if !fileManager.fileExists(atPath: videosSaveURL.path) {
        do {
            try fileManager.createDirectory(
                at: videosSaveURL, withIntermediateDirectories: true, attributes: nil)
                Logger.info("Created videos save path: \(videosSaveURL.path)")
        } catch {
            Logger.error("Failed to create videos save path: \(error)")
            return nil
        }
    }
    
    return videosSaveURL
}

func getVideoInfo(from fileURL: URL) async -> WallpaperItem? {
    guard (try? fileURL.checkResourceIsReachable()) == true else {
        return nil
    }
    
    let asset = AVURLAsset(url: fileURL)
    
    // 获取文件基本信息 (同步方式)
    let resourceValues = try? fileURL.resourceValues(forKeys: [
        .fileSizeKey,
        .creationDateKey,
        .contentTypeKey
    ])
    
    // 准备基础信息
    let title = fileURL.deletingPathExtension().lastPathComponent
    let filePath = "wallpapers/\(fileURL.lastPathComponent)"
    let fileSize = resourceValues?.fileSize ?? 0
    let creationDate = resourceValues?.creationDate ?? Date()
    let contentType = resourceValues?.contentType?.identifier ?? "unknown"
    
    // 异步加载轨道信息
    do {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else { return nil }
        
        // 并行加载所有需要的属性
        async let sizeTask = track.load(.naturalSize)
        async let transformTask = track.load(.preferredTransform)
        async let durationTask = asset.load(.duration)
        async let formatsTask = track.load(.formatDescriptions)
        
        // 等待所有任务完成
        let (size, transform, duration, formatDescriptions) = await (
            try sizeTask,
            try transformTask,
            try durationTask,
            try formatsTask
        )
        
        // 解析编码格式
        let codec: String = {
            guard let firstObj = (formatDescriptions as [AnyObject]).first,
                  let unmanaged = firstObj as? Unmanaged<CMFormatDescription> else {
                return "unknown"
            }
            let firstDesc = unmanaged.takeUnretainedValue()
            let codecType = CMFormatDescriptionGetMediaSubType(firstDesc)
            return codecType.fourCharCodeString
        }()
        
        // 计算分辨率（考虑旋转）
        let resolution: String = {
            guard size != .zero else { return "Unknown" }
            let realSize = size.applying(transform)
            return "\(abs(Int(realSize.width)))x\(abs(Int(realSize.height)))"
        }()
        
        // 计算时长
        let durationSeconds = duration.seconds
        
        return WallpaperItem(
            id: UUID(),
            title: title,
            fileUrl: fileURL,
            resolution: resolution,
            fileSize: fileSize,
            codec: codec,
            duration: durationSeconds,
            creationDate: creationDate,
        )
    } catch {
        print("Error loading asset properties: \(error)")
        return nil
    }
}

// FourCharCode 扩展
extension FourCharCode {
    var fourCharCodeString: String {
        let bytes = [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? "????"
    }
}

func importExternalVideo() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Select a Video."
    openPanel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
    openPanel.allowsMultipleSelection = false
    openPanel.begin { response in
        if response == .OK, let selectedURL = openPanel.url {
            do {
                if let videoSaveURL = getVideoSaveURL() {
                    let destinationURL = videoSaveURL.appendingPathComponent(selectedURL.lastPathComponent)
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                        Logger.info("Deleted existing file at: \(destinationURL.path)")
                    }
                    try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
                    Task { @MainActor in
                        if let item = await getVideoInfo(from: destinationURL) {
                            DatabaseManger.shared.addLocalVideo(item)
                            Logger.info("External wallpaper imported successfully. Path: \(destinationURL.path)")
                            NotificationCenter.default.post(name: .refreshLocalVideoList, object: nil)
                        }
                    }
                } else {
                    Logger.error("Failed to get wallpapers save path url!")
                }
            } catch {
                Logger.error("Failed to import external wallpaper. error: \(error)")
            }
        }
    }
}

func getCurrentVideoURL() -> URL? {
    if let path = UserDefaults.standard.string(forKey: "videoUrl") {
        return URL(fileURLWithPath: path)
    }
    return nil
}

func fileExists(at url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
}

func deleteFile(at url: URL) {
    if fileExists(at: url) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Logger.error("Failed to delete file: \(error)")
        }
    }
}

func addDefaultVideo() {
    let videoURL = Bundle.main.url(forResource: "codelume_0", withExtension: "mp4")
    let videoSaveURL = getVideoSaveURL()
    if let videoSaveURL = videoSaveURL, let videoURL = videoURL {
        let destinationURL = videoSaveURL.appendingPathComponent(videoURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                Logger.info("Deleted existing file at: \(destinationURL.path)")
            }
            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
            Task { @MainActor in
                if let item = await getVideoInfo(from: destinationURL) {
                    DatabaseManger.shared.addLocalVideo(item)
                    Logger.info("Default video imported successfully. Path: \(destinationURL.path)")
                    NotificationCenter.default.post(name: .refreshLocalVideoList, object: nil)
                }
            }
        } catch {
            Logger.error("Failed to add default video: \(error)")
        }
    }
}

func getDefaultVideoURL() -> URL? {
    if let videoSaveURL = getVideoSaveURL() {
        let videoURL = videoSaveURL.appendingPathComponent("codelume_0.mp4")
        return videoURL
    }
    return nil
}

// 下载资源文件中的屏保程序到指定目录，通过文件面板选择保存位置
func downloadScreensaver() {
    // 获取应用程序包中的屏保文件
    guard let saverURL = Bundle.main.url(forResource: "CodeLumeSaver", withExtension: "saver") else {
        Logger.error("Failed to find screensaver in bundle")
        return
    }
    
    // 创建保存面板
    let savePanel = NSSavePanel()
    savePanel.title = NSLocalizedString("Save Screen Saver", comment: "")
    savePanel.nameFieldStringValue = "CodeLume.saver"
    savePanel.allowedContentTypes = [UTType(filenameExtension: "saver") ?? .item]
    
    // 设置默认保存位置为桌面
    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    savePanel.directoryURL = desktopURL
    
    // 显示保存面板并处理用户选择
    savePanel.begin { response in
        if response == .OK, let destinationURL = savePanel.url {
            do {
                // 如果目标文件已存在，则先删除
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // 复制屏保文件到用户选择的位置
                try FileManager.default.copyItem(at: saverURL, to: destinationURL)
                Logger.info("Screensaver saved successfully to: \(destinationURL.path)")

                // 提供弹窗提示用户屏保已保存，双击安装即可生效
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Screensaver Saved", comment: "")
                    alert.informativeText = NSLocalizedString("Screensaver saved successfully!", comment: "")
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                    alert.runModal()
                }
            } catch {
                Logger.error("Failed to save screensaver: \(error)")
            }
        }
    }
}
