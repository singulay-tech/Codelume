//
//  SupabaseManager.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import Foundation
import Supabase
import AppKit

struct IAPVerifyResponse: Codable {
    let success: Bool
    let creditsGranted: Int
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case success
        case creditsGranted = "credits_granted"
        case balance
    }
}

struct WallpaperCreditsPurchaseResponse: Codable {
    let success: Bool
    let alreadyOwned: Bool
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case success
        case alreadyOwned = "already_owned"
        case balance
    }
}

struct WallpaperDownloadLinkResponse: Codable {
    let success: Bool
    let url: String
}

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
                Alert(title: "Register success!", message: "Please sign in with your email and password.")
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                Alert(title: "Register failed!", dynamicMessage: error.localizedDescription)
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
                Alert(title: "Sign in failed!", dynamicMessage: error.localizedDescription)
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
                Alert(title: "Apple ID sign in failed!", dynamicMessage: error.localizedDescription)
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
                    Alert(title: "Sign out failed.", dynamicMessage: error.localizedDescription)
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

    func getWallpaperVideoInfo(wallpaperId: UUID) async throws -> WallpaperVideoInfoTable? {
        let infos: [WallpaperVideoInfoTable] = try await client
            .from("wallpaper_video_info")
            .select()
            .eq("wallpaper_id", value: wallpaperId)
            .limit(1)
            .execute()
            .value

        return infos.first
    }

    func getCreditPackages() async throws -> [CreditPackageTable] {
        let packages: [CreditPackageTable] = try await client
            .from("iap_products")
            .select()
            .eq("is_active", value: true)
            .order("credits", ascending: true)
            .execute()
            .value
        return packages
    }

    func getUserCredits() async throws -> Int {
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let balances: [UserBalanceTable] = try await client
            .from("user_balances")
            .select()
            .eq("user_id", value: currentUser.id)
            .execute()
            .value
        return balances.first?.credits ?? 0
    }

    func hasPurchasedWallpaper(wallpaperId: UUID) async throws -> Bool {
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let entitlements: [WallpaperEntitlementTable] = try await client
            .from("wallpaper_entitlements")
            .select()
            .eq("user_id", value: currentUser.id)
            .eq("wallpaper_id", value: wallpaperId)
            .execute()
            .value
        return !entitlements.isEmpty
    }

    func verifyIAPPurchase(productId: String, transactionId: String, originalTransactionId: String?) async throws -> IAPVerifyResponse {
        struct VerifyBody: Codable {
            let productId: String
            let transactionId: String
            let originalTransactionId: String?

            enum CodingKeys: String, CodingKey {
                case productId = "product_id"
                case transactionId = "transaction_id"
                case originalTransactionId = "original_transaction_id"
            }
        }

        let body = VerifyBody(productId: productId, transactionId: transactionId, originalTransactionId: originalTransactionId)
        return try await invokeEdgeFunction(name: "verify-iap-purchase", body: body)
    }

    func purchaseWallpaperWithCredits(wallpaperId: UUID) async throws -> WallpaperCreditsPurchaseResponse {
        struct PurchaseBody: Codable {
            let wallpaperId: String

            enum CodingKeys: String, CodingKey {
                case wallpaperId = "wallpaper_id"
            }
        }

        let body = PurchaseBody(wallpaperId: wallpaperId.uuidString.lowercased())
        return try await invokeEdgeFunction(name: "purchase-wallpaper-with-credits", body: body)
    }

    func getPurchasedWallpaperDownloadURL(wallpaperId: UUID) async throws -> URL {
        struct DownloadBody: Codable {
            let wallpaperId: String

            enum CodingKeys: String, CodingKey {
                case wallpaperId = "wallpaper_id"
            }
        }

        Logger.info("[DownloadLink] Requesting purchased link. wallpaperId=\(wallpaperId.uuidString.lowercased())")

        let body = DownloadBody(wallpaperId: wallpaperId.uuidString.lowercased())
        let response: WallpaperDownloadLinkResponse
        do {
            response = try await invokeEdgeFunction(name: "create-purchased-download-link", body: body)
        } catch {
            Logger.error("[DownloadLink] Edge function call failed. error=\(error.localizedDescription)")
            throw error
        }
        Logger.info("[DownloadLink] Edge function response. success=\(response.success), rawUrl=\(response.url)")
        guard response.success, let url = URL(string: response.url) else {
            Logger.error("[DownloadLink] Invalid URL response. success=\(response.success), rawUrl=\(response.url)")
            throw NSError(domain: "SupabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL response"])
        }
        Logger.info("[DownloadLink] Parsed URL absoluteString=\(url.absoluteString)")
        return url
    }

    func getWallpaperPreviewURL(wallpaper: WallpaperTable) -> URL {
        let userId = wallpaper.userId.uuidString.lowercased()
        let wallpaperId = wallpaper.id.uuidString.lowercased()

        let url = supabaseUrl
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent("public")
            .appendingPathComponent("wallpaper-previews")
            .appendingPathComponent(userId)
            .appendingPathComponent(wallpaperId)
            .appendingPathComponent("preview.gif")

        Logger.info("Preview URL build userId=\(userId), wallpaperId=\(wallpaperId), url=\(url.absoluteString)")
        return url
    }

    private func invokeEdgeFunction<Response: Decodable, Body: Encodable>(name: String, body: Body) async throws -> Response {
        Logger.info("[EdgeFunction] Start invoke name=\(name)")

        Logger.info("[EdgeFunction] Fetching auth session for name=\(name)")
        let session = try await client.auth.session
        let accessToken = session.accessToken
        Logger.info("[EdgeFunction] Auth session ready for name=\(name), userId=\(session.user.id.uuidString.lowercased())")

        let endpoint = supabaseUrl.appendingPathComponent("functions/v1/\(name)")
        Logger.info("[EdgeFunction] Request endpoint=\(endpoint.absoluteString)")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        Logger.info("[EdgeFunction] Request body encoded bytes=\(request.httpBody?.count ?? 0), name=\(name)")

        let (data, response) = try await URLSession.shared.data(for: request)
        Logger.info("[EdgeFunction] Network response received bytes=\(data.count), name=\(name)")
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.error("[EdgeFunction] Non-HTTP response for name=\(name)")
            throw NSError(domain: "SupabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid edge function response"])
        }
        Logger.info("[EdgeFunction] HTTP status=\(httpResponse.statusCode), name=\(name)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Edge function failed"
            Logger.error("[EdgeFunction] HTTP error status=\(httpResponse.statusCode), name=\(name), body=\(errorMessage)")
            throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            Logger.info("[EdgeFunction] Decode success name=\(name)")
            return decoded
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            Logger.error("[EdgeFunction] Decode failed name=\(name), error=\(error.localizedDescription), raw=\(raw)")
            throw error
        }
    }
}
