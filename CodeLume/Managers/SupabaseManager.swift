//
//  SupabaseManager.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import Foundation
import Supabase
import AppKit

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    private static let supabaseUrlKey = "SUPABASE_URL"
    private static let supabaseAnonKey = "SUPABASE_ANON_KEY"

    private lazy var supabaseUrl: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: Self.supabaseUrlKey) as? String,
              let url = URL(string: urlString),
              !urlString.isEmpty else {
            fatalError("Missing or invalid SUPABASE_URL in Info.plist")
        }
        return url
    }()

    private lazy var supabaseKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: Self.supabaseAnonKey) as? String,
              !key.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        return key
    }()
    
    @Published var isLoading = false
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    lazy var client: SupabaseClient = {
        return SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
    }()
    
    private init() {
        isLoading = true
        listenForAuthChanges()
    }
    
    func listenForAuthChanges() {
        Task{
            for await (event, session) in client.auth.authStateChanges {
                switch event {
                case .initialSession:
                    await MainActor.run {
                        self.currentUser = session?.user
                        self.isAuthenticated = (session?.user != nil)
                        self.isLoading = false
                    }
                case .signedIn, .userUpdated:
                    await MainActor.run {
                        self.currentUser = session?.user
                        self.isAuthenticated = true
                        self.isLoading = false
                    }
                case .signedOut:
                    await MainActor.run {
                        self.currentUser = nil
                        self.isAuthenticated = false
                        self.isLoading = false
                    }
                default:
                    break
                }
            }
        }
    }
    
    func signUp(username: String, email: String, password: String) async -> Bool {
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let _ = try await client.auth.signUp(
                email: email,
                password: password
            )
            await MainActor.run {
                self.isLoading = false
                Alert(title: "Register success!", message: "Please log in with your email and password.")
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                Alert(title: "Register failed!", message: error.localizedDescription)
            }
            return false
        }
        return true
    }
    
    func signIn(email: String, password: String) async -> Bool {
        await MainActor.run {
            self.isLoading = true
        }
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            await MainActor.run {
                self.isLoading = false
                self.isAuthenticated = true
                self.currentUser = session.user
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                Alert(title: "Login failed!", message: error.localizedDescription)
            }
            return false
        }
        return true
    }

    func signInWithApple(idToken: String, nonce: String?) async -> Bool {
        await MainActor.run {
            self.isLoading = true
        }

        do {
            let credentials = OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )

            let session = try await client.auth.signInWithIdToken(credentials: credentials)
            await MainActor.run {
                self.isLoading = false
                self.isAuthenticated = true
                self.currentUser = session.user
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                Alert(title: "Apple login failed!", message: error.localizedDescription)
            }
            return false
        }

        return true
    }
    
    func signOut() {
        isLoading = true
        Task {
            do {
                try await client.auth.signOut()
            } catch {
                await MainActor.run {
                    Alert(title: "Login failed.", message: error.localizedDescription)
                }
            }
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func getCurrentUser() async throws -> Auth.User? {
        let session = try await client.auth.session
        return session.user
    }
    
    func getUserProfile() async throws -> UserTable {
        let session = try await client.auth.session
        let user = session.user
        
        
        let userTable = UserTable(id: user.id, email: user.email, username: user.role!, avatarUrl: nil, createdAt: .now, updatedAt: .now)
        return userTable
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        try await client.auth.update(
            user: UserAttributes(password: newPassword)
        )
    }
    
    func updateUserAvatar(avatarName: String) async throws {
        let authUser = try await getCurrentUser()
        guard let authUser else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let metadata = authUser.userMetadata
        //        metadata["avatar_name"] = avatarName
        
        try await client.auth.update(
            user: UserAttributes(data: metadata)
        )
    }
    
    //    func updateUserProfile(username: String? = nil, avatarUrl: String? = nil) async throws {
    //        let authUser = try await getCurrentUser()
    //        guard let userId = authUser?.id else {
    //            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
    //        }
    //
    //        var metadata = authUser?.userMetadata ?? [:]
    //
    //        if let newUsername = username {
    //            metadata["username"] = newUsername
    //        }
    //
    //        if let newAvatarUrl = avatarUrl {
    //            metadata["avatar_url"] = newAvatarUrl
    //        }
    //
    //        try await client.auth.update(user: UserAttributes(data: metadata))
    //    }
    
    func getWallpapers(page: Int = 1, limit: Int = 20) async throws -> [WallpaperTable] {
        let wallpapers: [WallpaperTable] = try await client
            .from("wallpapers")
            .select()
            .eq("is_approved", value: true)
            .order("created_at", ascending: false)
            .range(from: (page - 1) * limit, to: page * limit - 1)
            .execute()
            .value
        return wallpapers
    }
    
    func getWallpaper(id: UUID) async throws -> WallpaperTable {
        let response = try await client
            .from("wallpapers")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        let wallpaper = try JSONDecoder().decode(WallpaperTable.self, from: response.data)
        return wallpaper
    }
    
    func getUserWallpapers(userId: UUID) async throws -> [WallpaperTable] {
        let response = try await client
            .from("wallpapers")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let wallpapers = try JSONDecoder().decode([WallpaperTable].self, from: response.data)
        return wallpapers
    }
    
    func uploadWallpaper(title: String, description: String, price: Double, fileData: Data) async throws -> WallpaperTable {
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let wallpaperId = UUID()
        let filePath = "\(currentUser.id)/\(wallpaperId)/wallpaper.mp4"
        
        
        // 上传文件到存储
        try await client.storage
            .from("wallpapers")
            .upload(
                filePath,
                data: fileData
            )
        
        // 创建壁纸记录
        let response = try await client
            .from("wallpapers")
            .insert([
                "id": wallpaperId.uuidString,
                "user_id": currentUser.id.uuidString,
                "title": title,
                "description": description,
                "price": String(format: "%.2f", price),
                "file_path": filePath,
                "is_approved": String(false),
                "download_count": String(0)
            ])
            .select()
            .single()
            .execute()
        
        let wallpaper = try JSONDecoder().decode(WallpaperTable.self, from: response.data)
        return wallpaper
    }
    
    // MARK: - 下载相关
    
    //    func createDownload(wallpaperId: UUID) async throws -> [String: Any] {
    //        guard let currentUser = try await getCurrentUser() else {
    //            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
    //        }
    //
    //        // 调用 Edge Function 创建支付
    //        let response = try await client
    //            .functions
    //            .invoke("create-payment")
    //
    //        return response
    //    }
    
    //    func getPurchasedWallpapers() async throws -> [Wallpaper] {
    //        guard let currentUser = try await getCurrentUser() else {
    //            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
    //        }
    //
    //        let response = try await client
    //            .from("downloads")
    //            .select("wallpapers(*)")
    //            .eq("user_id", value: currentUser.id)
    //            .eq("status", value: "completed")
    //            .execute()
    //
    //        // 解析响应
    //        let data = try response.decoded(to: [[String: Any]].self)
    //
    //        let wallpapers = try data.compactMap { item -> Wallpaper? in
    //            if let wallpaperData = item["wallpapers"] as? [String: Any] {
    //                let jsonData = try JSONSerialization.data(withJSONObject: wallpaperData)
    //                return try JSONDecoder().decode(Wallpaper.self, from: jsonData)
    //            }
    //            return nil
    //        }
    //
    //        return wallpapers
    //    }
    
    // MARK: - 关注相关
    
    func followUser(followingId: UUID) async throws {
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await client
            .from("follows")
            .insert([
                "follower_id": currentUser.id,
                "following_id": followingId
            ])
            .execute()
    }
    
    func unfollowUser(followingId: UUID) async throws {
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await client
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUser.id)
            .eq("following_id", value: followingId)
            .execute()
    }
    
    //    func getFollowingUsers(userId: UUID) async throws -> [User] {
    //        let response = try await client
    //            .from("follows")
    //            .select("users!following_id(*)")
    //            .eq("follower_id", value: userId)
    //            .execute()
    //
    //        // 解析响应
    //        let data = try response.decoded(to: [[String: Any]].self)
    //        let users = try data.compactMap { item -> User? in
    //            if let userData = item["users"] as? [String: Any] {
    //                let jsonData = try JSONSerialization.data(withJSONObject: userData)
    //                return try JSONDecoder().decode(User.self, from: jsonData)
    //            }
    //            return nil
    //        }
    //
    //        return users
    //    }
    
    //    func getFollowers(userId: UUID) async throws -> [User] {
    //        let response = try await client
    //            .from("follows")
    //            .select("users!follower_id(*)")
    //            .eq("following_id", value: userId)
    //            .execute()
    //
    //        // 解析响应
    //        let data = try response.decoded(to: [[String: Any]].self)
    //        let users = try data.compactMap { item -> User? in
    //            if let userData = item["users"] as? [String: Any] {
    //                let jsonData = try JSONSerialization.data(withJSONObject: userData)
    //                return try JSONDecoder().decode(User.self, from: jsonData)
    //            }
    //            return nil
    //        }
    
    //        return users
    //    }
}
