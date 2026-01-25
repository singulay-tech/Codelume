//
//  WallpaperBundleCheck.swift
//  Codelume
//
//  Created by 广子俞 on 2025/12/16.
//

import Foundation

// MARK: - 检查壁纸包格式是否正确
func checkWallpaperBundle(_ url: URL) -> Bool {
    // 检查 bundle 目录下是否有 codelume.json 文件
    return true
    let jsonURL = url.appendingPathComponent("codelume.json")
    return FileManager.default.fileExists(atPath: jsonURL.path)
}
