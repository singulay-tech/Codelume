//
//  Utils.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/11.
//

import AVFoundation
import AppKit
import Foundation
import ServiceManagement
import UniformTypeIdentifiers

func fileExists(at url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
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

func importExternalWallpaper() {
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
    let wallpaperURL = Bundle.main.url(forResource: "thinking_cat", withExtension: "bundle")
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
        let wallpaperPath = wallpaperURL.appendingPathComponent("thinking_cat.bundle")
        return wallpaperPath
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

func setStaticWallpaper(bundleURL: URL, screenLocalName: String) -> Bool {
    // 构建缩略图文件路径：bundleURL/preview/thumbnail.jpg
    let previewDirectory = bundleURL.appendingPathComponent("preview")
    let thumbnailURL = previewDirectory.appendingPathComponent("thumbnail.jpg")
    
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
