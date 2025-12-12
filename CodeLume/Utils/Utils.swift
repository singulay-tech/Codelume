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

func getBundleSaveURL() -> URL? {
    let fileManager = FileManager.default
    guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    
    let bundleSaveURL = docDir.appendingPathComponent("Bundles")
    if !fileManager.fileExists(atPath: bundleSaveURL.path) {
        do {
            try fileManager.createDirectory(
                at: bundleSaveURL, withIntermediateDirectories: true, attributes: nil)
                Logger.info("Created bundle save path: \(bundleSaveURL.path)")
        } catch {
            Logger.error("Failed to create bundle save path: \(error)")
            return nil
        }
    }
    
    return bundleSaveURL
}

func importExternalBundle() {
    let openPanel = NSOpenPanel()
    openPanel.title = NSLocalizedString("Select a Bundle.", comment: "")
    openPanel.allowedContentTypes = [.bundle]
    openPanel.allowsMultipleSelection = false
    openPanel.begin { response in
        if response == .OK, let selectedURL = openPanel.url {
            do {
                if let bundleSaveURL = getBundleSaveURL() {
                    let destinationURL = bundleSaveURL.appendingPathComponent(selectedURL.lastPathComponent)
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                        Logger.info("Deleted existing file at: \(destinationURL.path)")
                    }
                    try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
                    Task { @MainActor in
                        if let item = await getBundleFileName(from: destinationURL) {
                            DatabaseManger.shared.addBundle(item)
                            Logger.info("External wallpaper imported successfully. Path: \(destinationURL.path)")
                            NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
                            
                            // 显示导入成功的弹窗
                            let alert = NSAlert()
                            alert.messageText = NSLocalizedString("Import Successful", comment: "")
                            alert.informativeText = NSLocalizedString("Bundle imported successfully. Please go to Local Wallpapers View to view it.", comment: "")
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

func deleteBundleFile(at fileName: String) {
    if let bundleSaveURL = getBundleSaveURL() {
        let fileURL = bundleSaveURL.appendingPathComponent(fileName)
        if fileExists(at: fileURL) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                Logger.error("Failed to delete file: \(error)")
            }   
        }
    }
}

func getBundleFileName(from url: URL) async -> String? {
    let fileName = url.deletingPathExtension().lastPathComponent
    return fileName
}

func addDefaultBundle() {
    let bundleURL = Bundle.main.url(forResource: "thinking_cat", withExtension: "bundle")
    let bundleSaveURL = getBundleSaveURL()
    if let bundleSaveURL = bundleSaveURL, let bundleURL = bundleURL {
        let destinationURL = bundleSaveURL.appendingPathComponent(bundleURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                Logger.info("Deleted existing file at: \(destinationURL.path)")
            }
            try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
            Task { @MainActor in
                if let item = await getBundleFileName(from: destinationURL) {
                    DatabaseManger.shared.addBundle(item)
                    Logger.info("Default bundle imported successfully. Path: \(destinationURL.path)")
                    NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
                }
            }
        } catch {
            Logger.error("Failed to add default video: \(error)")
        }
    }
}

func getDefaultBundleURL() -> URL? {
    if let bundleURL = getBundleSaveURL() {
        let bundlePath = bundleURL.appendingPathComponent("thinking_cat.bundle")
        return bundlePath
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
