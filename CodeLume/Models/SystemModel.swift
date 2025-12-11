//
//  SystemModel.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/11.
//

import Foundation

// MARK: - 语言
enum Language: String, CaseIterable {
        case system = "Follow system"
        case chinese = "Chinese"
        case english = "English"
}

// MARK: - 主题
enum Theme: String, CaseIterable {
        case system = "Follow system"
        case light = "Light"
        case dark = "Dark"
    }