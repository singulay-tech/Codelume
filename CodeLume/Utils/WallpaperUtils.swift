//
//  WallpaperUtils.swift
//  CodeLume
//
//  Created by Lyke on 2025/3/20.
//

import AppKit
import AVFoundation
import Foundation
import ServiceManagement

func setFirstFrameAsWallpaper(videoURL: URL) -> Bool {
    let asset = AVAsset(url: videoURL)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    do {
        let cgImage = try imageGenerator.copyCGImage(
            at: CMTime(seconds: 0, preferredTimescale: 60), actualTime: nil)
        let image = NSImage(
            cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return setWallpaper(image: image, name: videoURL.deletingPathExtension().lastPathComponent)
    } catch {
        Logger.error("Error extracting first frame: \(error).")
        return false
    }
}

// 新的setFirstFrameAsWallpaper接口，支持传入屏幕localname参数
func setFirstFrameAsWallpaper(videoURL: URL, screenLocalName: String) -> Bool {
    let asset = AVAsset(url: videoURL)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    do {
        let cgImage = try imageGenerator.copyCGImage(
            at: CMTime(seconds: 0, preferredTimescale: 60), actualTime: nil)
        let image = NSImage(
            cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        // 调用带屏幕参数的setWallpaper函数
        let name = videoURL.deletingPathExtension().lastPathComponent
        return setWallpaper(image: image, name: name, screenLocalName: screenLocalName)
    } catch {
        Logger.error("Error extracting first frame for screen \(screenLocalName): \(error).")
        return false
    }
}

func setWallpaper(image: NSImage, name: String) -> Bool {
    let fileManager = FileManager.default
    guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        Logger.error("Cannot get document directory.")
        return false
    }
    let imageDir = docDir.appendingPathComponent("currentwallpaper")
    let imageURL = imageDir.appendingPathComponent("\(name).jpg")
    
    do {
        if !fileManager.fileExists(atPath: imageDir.path) {
            try fileManager.createDirectory(at: imageDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        guard let imageData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: imageData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) else {
            Logger.error("Failed to generate jpeg data.")
            return false
        }
        try jpegData.write(to: imageURL)
        
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
        ]
        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            try? workspace.setDesktopImageURL(imageURL, for: screen, options: options)
        }
        
        let files = try fileManager.contentsOfDirectory(at: imageDir, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "jpg" && file != imageURL {
            try fileManager.removeItem(at: file)
        }
    } catch {
        Logger.error("Error setting wallpaper: \(error).")
        return false
    }
    
    Logger.info("Set wallpaper success for \(imageURL).")
    return true
}

// 新的setWallpaper接口，支持传入屏幕localname参数
func setWallpaper(image: NSImage, name: String, screenLocalName: String) -> Bool {
    let fileManager = FileManager.default
    guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        Logger.error("Cannot get document directory.")
        return false
    }
    
    let imageDir = docDir.appendingPathComponent("currentwallpaper")

    // 确保目录存在，如果不存在则创建
    do {
        if !fileManager.fileExists(atPath: imageDir.path) {
            try fileManager.createDirectory(at: imageDir, withIntermediateDirectories: true, attributes: nil)
            Logger.info("Created directory: \(imageDir.path)")
        }
    } catch {
        Logger.error("Failed to create directory \(imageDir.path): \(error)")
        return false
    }
    
    // 以"屏幕名字+name"的方式保存图片
    let screenSpecificImageName = "\(screenLocalName)\(name).jpg"
    let imageURL = imageDir.appendingPathComponent(screenSpecificImageName)
    
    do {
        // 将图片转换为JPEG并保存
        guard let imageData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: imageData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) else {
            Logger.error("Failed to generate jpeg data.")
            return false
        }
        try jpegData.write(to: imageURL)
        
        // 设置壁纸选项
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
        ]
        
        let workspace = NSWorkspace.shared
        var isScreenFound = false
        
        // 查找并设置指定屏幕的壁纸
        for screen in NSScreen.screens {
            // 使用NSScreen的localizedName来匹配
            if screen.localizedName == screenLocalName {
                try workspace.setDesktopImageURL(imageURL, for: screen, options: options)
                isScreenFound = true
                Logger.info("Set wallpaper success for screen \(screenLocalName) with image \(imageURL).")
                break
            }
        }
        
        if !isScreenFound {
            Logger.error("Screen with name \(screenLocalName) not found.")
            return false
        }
        
        // 清理与当前屏幕相关的其他图片，但保留其他屏幕的图片
        let files = try fileManager.contentsOfDirectory(at: imageDir, includingPropertiesForKeys: nil)
        for file in files {
            // 只清理和当前屏幕相关的其他图片，不要清理其他屏幕或者格式不匹配的图片
            let fileName = file.lastPathComponent
            if fileName.hasPrefix(screenLocalName) && fileName.hasSuffix(".jpg") && file != imageURL {
                try fileManager.removeItem(at: file)
                Logger.info("Cleaned up old wallpaper file: \(fileName)")
            }
        }
    } catch {
        Logger.error("Error setting wallpaper for screen \(screenLocalName): \(error).")
        return false
    }
    
    return true
}
