//
//  Table.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//
import Foundation

struct UserTable: Codable {
    let id: UUID
    let email: String?
    let username: String
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WallpaperTable: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let filePath: String
    let thumbnailPath: String?
    let price: Double
    let isApproved: Bool
    let downloadCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case filePath = "file_path"
        case thumbnailPath = "thumbnail_path"
        case price
        case isApproved = "is_approved"
        case downloadCount = "download_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Download: Codable {
    let id: Int
    let userId: UUID
    let wallpaperId: UUID
    let amount: Double
    let serviceFee: Double
    let status: String
    let createdAt: Date
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case wallpaperId = "wallpaper_id"
        case amount
        case serviceFee = "service_fee"
        case status
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

struct Payment: Codable {
    let id: String
    let userId: UUID
    let downloadId: Int
    let amount: Double
    let currency: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case downloadId = "download_id"
        case amount
        case currency
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Follow: Codable {
    let id: Int
    let followerId: UUID
    let followingId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}
