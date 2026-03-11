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
    let name: String
    let description: String
    let author: String
    let authorEmail: String
    let wallpaperType: String
    let categoryId: Int
    let bundleSizeMB: Decimal
    let totalDownloads: Int
    let totalPurchases: Int
    let creditsCost: Int
    let isApproved: Bool
    let bundleSHA256: String
    let createdAt: Date
    let updatedAt: Date

    private static let defaultUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case author
        case authorEmail = "author_email"
        case wallpaperType = "type"
        case categoryId = "category_id"
        case bundleSizeMB = "bundle_size_mb"
        case totalDownloads = "total_downloads"
        case totalPurchases = "total_purchases"
        case creditsCost = "credits_cost"
        case isApproved = "is_approved"
        case bundleSHA256 = "bundle_sha256"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId) ?? Self.defaultUserId
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
        authorEmail = try container.decodeIfPresent(String.self, forKey: .authorEmail) ?? ""
        wallpaperType = try container.decodeIfPresent(String.self, forKey: .wallpaperType) ?? "video"
        categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId) ?? 0
        bundleSizeMB = try container.decodeIfPresent(Decimal.self, forKey: .bundleSizeMB) ?? .zero
        totalDownloads = try container.decodeIfPresent(Int.self, forKey: .totalDownloads) ?? 0
        totalPurchases = try container.decodeIfPresent(Int.self, forKey: .totalPurchases) ?? 0
        creditsCost = try container.decodeIfPresent(Int.self, forKey: .creditsCost) ?? 0
        isApproved = try container.decodeIfPresent(Bool.self, forKey: .isApproved) ?? false
        bundleSHA256 = try container.decodeIfPresent(String.self, forKey: .bundleSHA256) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct CreditPackageTable: Codable, Identifiable {
    let id: UUID
    let productId: String
    let credits: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case credits
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserBalanceTable: Codable {
    let userId: UUID
    let credits: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case credits
        case updatedAt = "updated_at"
    }
}

struct PurchaseTransactionTable: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let transactionId: String
    let originalTransactionId: String?
    let productId: String
    let creditsGranted: Int
    let status: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case productId = "product_id"
        case creditsGranted = "credits_granted"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WallpaperEntitlementTable: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let wallpaperId: UUID
    let source: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case wallpaperId = "wallpaper_id"
        case source
        case createdAt = "created_at"
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
