import SwiftUI
import ImageIO

private enum PriceFilter: String, CaseIterable, Identifiable {
    case all = "All Prices"
    case free = "Free Only"
    case paid = "Paid Only"
    
    var id: String { rawValue }
}

struct WallpaperHubView: View {
    @State private var wallpapers: [WallpaperTable] = []
    @State private var videoInfoByWallpaperId: [UUID: WallpaperVideoInfoTable] = [:]
    @State private var loadingVideoInfoIds: Set<UUID> = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var searchText = ""
    @State private var selectedCategoryId: Int? = nil
    @State private var selectedPriceFilter: PriceFilter = .all
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let pageSize = 20
    
    @ObservedObject private var supabase = SupabaseManager.shared
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if supabase.isAuthenticated == false {
                ContentUnavailableView("Sign in to access the Wallpaper Hub.", systemImage: "photo.on.rectangle.angled")
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(filteredWallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                                VStack(alignment: .leading, spacing: 6) {
                                    PreviewWallpaperGIF(url: supabase.getWallpaperPreviewURL(wallpaper: wallpaper))
                                        .aspectRatio(16 / 9, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    
                                    HStack() {
                                        Text(wallpaper.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        WallpaperTypeLabel(type: wallpaper.wallpaperType)
                                        
                                        Spacer()
                                        
                                        Text(wallpaper.author.isEmpty ? "Unknown Author" : wallpaper.author)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    
                                    if isVideoWallpaper(wallpaper) {
                                        WallpaperVideoInfoInline(
                                            info: videoInfoByWallpaperId[wallpaper.id],
                                            isLoading: loadingVideoInfoIds.contains(wallpaper.id)
                                        )
                                        .task(id: wallpaper.id) {
                                            await loadVideoInfoIfNeeded(for: wallpaper)
                                        }
                                    }
                                    
                                    Text(wallpaper.description.isEmpty ? "No description" : wallpaper.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    ServerWallpaperPurchaseView(wallpaper: wallpaper)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.regularMaterial)
                                )
                                .onAppear {
                                    Task {
                                        await loadMoreIfNeeded(currentWallpaperID: wallpaper.id, filteredIndex: index)
                                    }
                                }
                            }
                            
                            if isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .gridCellColumns(columns.count)
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task(id: supabase.isAuthenticated) {
            if supabase.isAuthenticated {
                await loadInitialWallpapers()
            } else {
                wallpapers = []
                videoInfoByWallpaperId = [:]
                loadingVideoInfoIds = []
                currentPage = 1
                hasMorePages = true
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var availableCategoryIds: [Int] {
        Array(Set(wallpapers.map(\.categoryId))).sorted()
    }
    
    private var filteredWallpapers: [WallpaperTable] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return wallpapers
            .filter { wallpaper in
                let matchesSearch: Bool
                if trimmedSearch.isEmpty {
                    matchesSearch = true
                } else {
                    let target = trimmedSearch.lowercased()
                    matchesSearch = wallpaper.name.lowercased().contains(target)
                    || wallpaper.author.lowercased().contains(target)
                    || wallpaper.description.lowercased().contains(target)
                }
                
                let matchesCategory = selectedCategoryId == nil || wallpaper.categoryId == selectedCategoryId
                
                let matchesPrice: Bool
                switch selectedPriceFilter {
                case .all:
                    matchesPrice = true
                case .free:
                    matchesPrice = wallpaper.creditsCost == 0
                case .paid:
                    matchesPrice = wallpaper.creditsCost > 0
                }
                
                return matchesSearch && matchesCategory && matchesPrice
            }
    }
    
    private func isVideoWallpaper(_ wallpaper: WallpaperTable) -> Bool {
        wallpaper.wallpaperType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "video"
    }
    
    @MainActor
    private func loadVideoInfoIfNeeded(for wallpaper: WallpaperTable) async {
        guard isVideoWallpaper(wallpaper) else { return }
        guard videoInfoByWallpaperId[wallpaper.id] == nil else { return }
        guard !loadingVideoInfoIds.contains(wallpaper.id) else { return }
        
        loadingVideoInfoIds.insert(wallpaper.id)
        defer { loadingVideoInfoIds.remove(wallpaper.id) }
        
        do {
            let info = try await supabase.getWallpaperVideoInfo(wallpaperId: wallpaper.id)
            if let info {
                videoInfoByWallpaperId[wallpaper.id] = info
            }
        } catch {
            guard !(error is CancellationError) else { return }
            let nsError = error as NSError
            guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
            Logger.warning("Load wallpaper_video_info failed: \(error.localizedDescription)")
        }
    }
    
    private func loadInitialWallpapers() async {
        isLoading = true
        defer { isLoading = false }
        currentPage = 1
        hasMorePages = true
        videoInfoByWallpaperId = [:]
        loadingVideoInfoIds = []
        
        do {
            let firstPage = try await supabase.getWallpapers(page: currentPage, limit: pageSize)
            wallpapers = firstPage
            hasMorePages = firstPage.count == pageSize
        } catch {
            guard !(error is CancellationError) else { return }
            let nsError = error as NSError
            guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
            Alert(title: "Load failed", dynamicMessage: error.localizedDescription)
        }
    }
    
    private func loadMoreIfNeeded(currentWallpaperID: UUID, filteredIndex: Int) async {
        guard hasMorePages, !isLoading, !isLoadingMore else { return }
        guard filteredIndex >= filteredWallpapers.count - 4 else { return }
        guard let sourceIndex = wallpapers.firstIndex(where: { $0.id == currentWallpaperID }) else { return }
        guard sourceIndex >= wallpapers.count - 6 || !searchText.isEmpty || selectedCategoryId != nil || selectedPriceFilter != .all else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let nextPage = currentPage + 1
            let nextWallpapers = try await supabase.getWallpapers(page: nextPage, limit: pageSize)
            wallpapers.append(contentsOf: nextWallpapers)
            currentPage = nextPage
            hasMorePages = nextWallpapers.count == pageSize
        } catch {
            guard !(error is CancellationError) else { return }
            let nsError = error as NSError
            guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
            Alert(title: "Load failed", dynamicMessage: error.localizedDescription)
        }
    }
}

#Preview {
    WallpaperHubView()
}
