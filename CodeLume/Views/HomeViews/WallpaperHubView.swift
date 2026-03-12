import SwiftUI
import ImageIO

struct WallpaperHubView: View {
    @State private var wallpapers: [WallpaperTable] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var hasMorePages = true
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
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                            VStack(alignment: .leading, spacing: 10) {
                                PreviewImage(url: supabase.getWallpaperPreviewURL(wallpaper: wallpaper))
                                    .aspectRatio(16 / 9, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                
                                HStack() {
                                    Text(wallpaper.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(wallpaper.author.isEmpty ? "Unknown Author" : wallpaper.author)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                
                                Text(wallpaper.description.isEmpty ? "No description" : wallpaper.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
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
                                    await loadMoreIfNeeded(currentIndex: index)
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
                    .padding(.horizontal, 24)
                    .padding(.top, 0)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .task(id: supabase.isAuthenticated) {
            if supabase.isAuthenticated {
                await loadInitialWallpapers()
            } else {
                wallpapers = []
                currentPage = 1
                hasMorePages = true
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
    
    private func loadInitialWallpapers() async {
        isLoading = true
        defer { isLoading = false }
        currentPage = 1
        hasMorePages = true
        
        do {
            let firstPage = try await supabase.getWallpapers(page: currentPage, limit: pageSize)
            wallpapers = firstPage
            hasMorePages = firstPage.count == pageSize
        } catch {
            guard !(error is CancellationError) else { return }
            let nsError = error as NSError
            guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
            Alert(title: "Load failed", message: error.localizedDescription)
        }
    }

    private func loadMoreIfNeeded(currentIndex: Int) async {
        guard hasMorePages, !isLoading, !isLoadingMore else { return }
        guard currentIndex >= wallpapers.count - 4 else { return }

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
            Alert(title: "Load failed", message: error.localizedDescription)
        }
    }
}

private struct PreviewImage: View {
    let url: URL
    @State private var retryID = 0
    @State private var gifData: Data?
    @State private var isLoading = false
    @State private var loadFailed = false
    
    var body: some View {
        ZStack {
            if let gifData {
                AnimatedGIFView(data: gifData)
            } else if isLoading {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                ProgressView()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                if loadFailed {
                    Button {
                        loadFailed = false
                        gifData = nil
                        isLoading = false
                        retryID += 1
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                            Text("Retry")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .id(retryID)
        .task(id: retryID) {
            await loadGIF()
        }
        .clipped()
    }
    
    private func loadGIF() async {
        isLoading = true
        loadFailed = false
        gifData = nil
        defer { isLoading = false }
        
        if let cachedData = GIFDataCache.data(for: url) {
            gifData = cachedData
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            let (data, _) = try await URLSession.shared.data(for: request)
            guard GIFAnimation(data: data) != nil else {
                loadFailed = true
                return
            }
            GIFDataCache.store(data, for: url)
            gifData = data
        } catch {
            loadFailed = true
        }
    }
    
    private enum GIFDataCache {
        private static let cache = NSCache<NSURL, NSData>()
        
        static func data(for url: URL) -> Data? {
            cache.object(forKey: url as NSURL) as Data?
        }
        
        static func store(_ data: Data, for url: URL) {
            cache.setObject(data as NSData, forKey: url as NSURL)
        }
    }
}

private struct AnimatedGIFView: View {
    private let animation: GIFAnimation?
    @State private var startDate = Date()
    
    init(data: Data) {
        self.animation = GIFAnimation(data: data)
    }
    
    var body: some View {
        Group {
            if let animation {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    Image(decorative: animation.frame(at: timeline.date, relativeTo: startDate), scale: 1)
                        .resizable()
                        .scaledToFit()
                }
            } else {
                Color.clear
            }
        }
        .onAppear {
            startDate = Date()
        }
    }
}

private struct GIFAnimation {
    struct Frame {
        let image: CGImage
        let duration: TimeInterval
    }
    
    let frames: [Frame]
    let totalDuration: TimeInterval
    
    init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else {
            return nil
        }
        
        var decodedFrames: [Frame] = []
        var durationSum: TimeInterval = 0
        
        for index in 0..<frameCount {
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            
            let frameDuration = Self.frameDuration(for: source, at: index)
            decodedFrames.append(Frame(image: image, duration: frameDuration))
            durationSum += frameDuration
        }
        
        guard !decodedFrames.isEmpty else {
            return nil
        }
        
        self.frames = decodedFrames
        self.totalDuration = max(durationSum, 0.1)
    }
    
    func frame(at date: Date, relativeTo startDate: Date) -> CGImage {
        let elapsed = date.timeIntervalSince(startDate).truncatingRemainder(dividingBy: totalDuration)
        var accumulated: TimeInterval = 0
        
        for frame in frames {
            accumulated += frame.duration
            if elapsed < accumulated {
                return frame.image
            }
        }
        
        return frames[frames.count - 1].image
    }
    
    private static func frameDuration(for source: CGImageSource, at index: Int) -> TimeInterval {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.1
        }
        
        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let delay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
        let duration = unclampedDelay ?? delay ?? 0.1
        
        return duration < 0.011 ? 0.1 : duration
    }
}

#Preview {
    WallpaperHubView()
}
