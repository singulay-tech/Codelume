//
//  Utils.swift
//  Codelume
//
//  Created by 广子俞 on 2025/12/11.
//

import AVFoundation
import AppKit
import Foundation
import ServiceManagement
import UniformTypeIdentifiers
import CodelumeBundle

func fileExists(at url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
}

// MARK: - 视频处理辅助函数

/// 从视频 URL 生成缩略图
/// - Parameter videoURL: 视频文件的 URL
/// - Returns: 生成的缩略图 UIImage，与视频原始尺寸相同
func generateThumbnail(from videoURL: URL) throws -> NSImage {
    let asset = AVAsset(url: videoURL)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    // 移除最大尺寸限制，生成原图大小的缩略图
    // imageGenerator.maximumSize = CGSize(width: 200, height: 200)
    
    let time = CMTime(seconds: 0.0, preferredTimescale: 600)
    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
    
    // 获取原始视频尺寸
    let videoSize = CGSize(width: cgImage.width, height: cgImage.height)
    Logger.info("Generated thumbnail with original video size: \(videoSize)")
    
    return NSImage(cgImage: cgImage, size: videoSize)
}

// MARK: - NSImage 扩展

extension NSImage {
    /// 将 NSImage 转换为 JPEG 数据
    /// - Parameter compressionQuality: JPEG 压缩质量 (0.0 - 1.0)
    /// - Returns: 生成的 JPEG 数据
    func toJPEGData(compressionQuality: CGFloat) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        
        return bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}

func getWallpaperSaveURL() -> URL? {
    let fileManager = FileManager.default
    guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }

    let wallpaperSaveURL = docDir.appendingPathComponent("Wallpapers")
    if !fileManager.fileExists(atPath: wallpaperSaveURL.path) {
        do {
            try fileManager.createDirectory(
                at: wallpaperSaveURL, withIntermediateDirectories: true, attributes: nil)
                Logger.info("Created wallpaper save path: \(wallpaperSaveURL.path)")
        } catch {
            Logger.error("Failed to create wallpaper save path: \(error)")
            return nil
        }
    }
    
    return wallpaperSaveURL
}

func importBundle() {
    let openPanel = NSOpenPanel()
    openPanel.title = NSLocalizedString("Select a Wallpaper Bundle.", comment: "")
    openPanel.allowedContentTypes = [.bundle]
    openPanel.allowsMultipleSelection = false
    openPanel.begin { response in
        if response == .OK, let selectedURL = openPanel.url {
            do {
                // 检查壁纸包格式是否正确
                if !checkWallpaperBundle(selectedURL) {
                    Logger.error("Invalid wallpaper bundle format.")
                    
                    // 显示导入失败的弹窗
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Import Failed", comment: "")
                    alert.informativeText = NSLocalizedString("The selected file is not a valid wallpaper bundle.", comment: "")
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                    alert.runModal()
                    return
                }
                
                if let wallpaperSaveURL = getWallpaperSaveURL() {
                    let destinationURL = wallpaperSaveURL.appendingPathComponent(selectedURL.lastPathComponent)
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                        Logger.info("Deleted existing wallpaper file at: \(destinationURL.path)")
                    }
                    try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
                    Task { @MainActor in
                        if let item = await getWallpaperFileName(from: destinationURL) {
                            DatabaseManger.shared.addWallpaper(item)
                            NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
                            Logger.info("External wallpaper imported successfully. Path: \(destinationURL.path)")

                            let alert = NSAlert()
                            alert.messageText = NSLocalizedString("Import Successful", comment: "")
                            alert.informativeText = NSLocalizedString("Wallpaper imported successfully. Please go to Local Wallpapers View to view it.", comment: "")
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                            alert.runModal()
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

func importVideo() {
    let openPanel = NSOpenPanel()
    openPanel.title = NSLocalizedString("Select a Video.", comment: "")
    openPanel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
    openPanel.allowsMultipleSelection = false
    openPanel.begin { response in
        if response == .OK, let selectedURL = openPanel.url {
            let wallpaperBundele = VideoBundle()
            let bundleName = selectedURL.deletingPathExtension().lastPathComponent
            
            var ret = wallpaperBundele.create(bundleName: bundleName, saveDir: WALLPAPER_SAVE_URL)
            if !ret {
                Alert(title: NSLocalizedString("Import Failed", comment: ""), message: NSLocalizedString("Failed to create wallpaper bundle.", comment: ""), style: .critical)
                return
            }

            ret = wallpaperBundele.addVideo(videoUrl: selectedURL)
            if !ret {
                Alert(title: NSLocalizedString("Import Failed", comment: ""), message: NSLocalizedString("Failed to add video to wallpaper bundle.", comment: ""), style: .critical)
                return
            }

            ret = wallpaperBundele.save()
            if !ret {
                Alert(title: NSLocalizedString("Import Failed", comment: ""), message: NSLocalizedString("Failed to save wallpaper bundle.", comment: ""), style: .critical)    
                return
            }
            
            DatabaseManger.shared.addWallpaper(bundleName)
            NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)

            Alert(title: NSLocalizedString("Import Successful", comment: ""), message: NSLocalizedString("Wallpaper imported successfully. Please go to Local Wallpapers View to view it.", comment: ""), style: .informational)
        }
    }
}

func deleteWallpaperFile(at fileName: String) {
    if let wallpaperSaveURL = getWallpaperSaveURL() {
        let fileURL = wallpaperSaveURL.appendingPathComponent(fileName).appendingPathExtension("bundle")
        if fileExists(at: fileURL) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                Logger.info("Deleted wallpaper file at: \(fileURL.path)")
            } catch {
                Logger.error("Failed to delete wallpaper file: \(error)")
            }   
        } else {
            Logger.error("Wallpaper file does not exist at: \(fileURL.path)")
        }
    }
}

func getWallpaperFileName(from url: URL) async -> String? {
    let fileName = url.deletingPathExtension().lastPathComponent
    return fileName
}

func addDefaultWallpaper() {
    let wallpaperURL = Bundle.main.url(forResource: "DefaultBundle", withExtension: "bundle")
    let wallpaperSaveURL = getWallpaperSaveURL()
    if let wallpaperSaveURL = wallpaperSaveURL, let wallpaperURL = wallpaperURL {
        let destinationURL = wallpaperSaveURL.appendingPathComponent(wallpaperURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                Logger.info("Default wallpaper already exists. Path: \(destinationURL.path)")
                return
            }
            try FileManager.default.copyItem(at: wallpaperURL, to: destinationURL)
            Task { @MainActor in
                if let item = await getWallpaperFileName(from: destinationURL) {
                    DatabaseManger.shared.addWallpaper(item)
                    Logger.info("Default wallpaper imported successfully. Path: \(destinationURL.path)")
                    NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
                }
            }
        } catch {
            Logger.error("Failed to add default wallpaper: \(error)")
        }
    }
}

func getDefaultWallpaperURL() -> URL? {
    if let wallpaperURL = getWallpaperSaveURL() {
        let wallpaperPath = wallpaperURL.appendingPathComponent("DefaultBundle.bundle")
        return wallpaperPath
    }
    return nil
}

func setStaticWallpaper(bundleURL: URL, screenLocalName: String) -> Bool {
    // 构建缩略图文件路径：bundleURL/preview/thumbnail.jpg
    let previewDirectory = bundleURL.appendingPathComponent("Preview")
    let thumbnailURL = previewDirectory.appendingPathComponent("Preview.jpg")
    
    do {
        // 检查缩略图文件是否存在
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: thumbnailURL.path) else {
            Logger.error("Thumbnail file not found at \(thumbnailURL.path)")
            return false
        }
        
        // 设置壁纸选项
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
        ]
        
        // 查找并设置指定屏幕的壁纸
        let workspace = NSWorkspace.shared
        var isScreenFound = false
        
        for screen in NSScreen.screens {
            // 使用NSScreen的localizedName来匹配
            if screen.localizedName == screenLocalName {
                try workspace.setDesktopImageURL(thumbnailURL, for: screen, options: options)
                isScreenFound = true
                Logger.info("Set static wallpaper success for screen \(screenLocalName) with image \(thumbnailURL).")
                break
            }
        }
        
        if !isScreenFound {
            Logger.error("Screen with name \(screenLocalName) not found.")
            return false
        }
        
        return true
    } catch {
        Logger.error("Error setting static wallpaper for screen \(screenLocalName): \(error).")
        return false
    }
}

func Alert(title: String, message: String, style: NSAlert.Style) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = style
    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
    alert.runModal()
}
