
//  WallpaperHubViews.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/16.

import SwiftUI

struct WallpaperHubView: View {
    @State private var wallpaperItems: [URL] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        VStack {
            if isLoading {
                VStack {
                    ProgressView("Loading wallpapers...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .font(.headline)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.headline)
                        .padding()
                    Button(action: loadHubWallpapers) {
                        Text("Retry")
                            .padding()
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(wallpaperItems, id: \.self) { url in
                            WallpaperHubItemView(wallpaperURL: url)
                                .aspectRatio(16 / 9, contentMode: .fit)
                        }
                    }
                    .padding()
                    
                    if wallpaperItems.isEmpty {
                        Text("No wallpapers available.")
                            .font(.headline)
                            .padding()
                    }
                }
            }
        }
        .task {
            loadHubWallpapers()
        }
    }
    
    private func loadHubWallpapers(){
        Logger.info("Load hub wallpapers.")
        
        isLoading = true
        errorMessage = nil
        wallpaperItems.removeAll()
        
        Task {
            do {
                let wallpapers = try await SupabaseManager.shared.getAllWallpaperBundlesInfo()
                Logger.info("load \(wallpapers.count) wallpapers form supabase")
                
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let wallpapersSaveURL = documentsDirectory.appendingPathComponent("tmp")
                
                do {
                    try FileManager.default.createDirectory(at: wallpapersSaveURL, withIntermediateDirectories: true)
                } catch {
                    Logger.error("Failed to create tmp directory: \(error)")
                }
                
                var items: [URL] = []
                for wallpaper in wallpapers {
                    items.append(wallpaper)
                    Logger.info("append \(wallpaper) to wallpaperItems.")
                }
                
                await MainActor.run {
                    wallpaperItems = items
                    isLoading = false
                }
            } catch {
                Logger.error("Failed to load hub wallpapers: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to load hub wallpapers."
                    isLoading = false
                }
            }
        }
    }
}

struct WallpaperHubItemView: View {
    let wallpaperURL: URL
    @State private var isHovering = false
    @State private var thumbnailImage: Image?
    @State private var isShowingPreview = false
    @State private var isShowingDetails = false
    @State private var isButtonDisabled = false
    @State private var isDownloading = false
    private let buttonDelay: Double = 0.5
    
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            if let thumbnailImage = thumbnailImage {
                thumbnailImage
                    .resizable()
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .cornerRadius(8)
            } else {
                Color.gray
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .cornerRadius(8)
            }
            
            if isHovering {
                HStack(spacing: 8) {
                    WallpaperNameLabel(text: wallpaperURL.lastPathComponent)
                    Spacer()
                    VideoFloatButton(text: "Details", action: debouncedAction{isShowingDetails = true})
                    VideoFloatButton(text: "Download", action: debouncedAction(downloadWallpaper))
                }
                .padding(8)
            }
        }
        .sheet(isPresented: $isShowingDetails) {
            ZStack(alignment: .topLeading) {
                DetailsView(wallpaperURL: wallpaperURL)
                    .padding(20)
                CloseButton(action: { isShowingDetails = false })
            }
        }
        .sheet(isPresented: $isDownloading) {
            DownloadingAlert()
        }
        .onAppear {
            generateThumbnail()
        }
        .onHover { hovering in
            withAnimation(.easeInOut) {
                isHovering = hovering
            }
        }
    }
    
    private func downloadWallpaper() {
        if isDownloading == true {
            Alert(title: NSLocalizedString("Downloading", comment: ""), message: NSLocalizedString("Wallpaper is downloading.", comment: ""), style: .informational)
            return
        }

        Task {
            isDownloading = true
            let success = await SupabaseManager.shared.downloadWallpaper(name: wallpaperURL.deletingPathExtension().lastPathComponent)
            if success {
                // 从 tmp 拷贝 到 wallpapers 目录，如果存在则替换
                let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let wallpapersDir = documentsDir.appendingPathComponent("Wallpapers")
                try? FileManager.default.createDirectory(at: wallpapersDir, withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: wallpapersDir.appendingPathComponent("\(wallpaperURL.lastPathComponent)").path) {
                    Alert(title: NSLocalizedString("Download Success", comment: ""), message: NSLocalizedString("Wallpaper \(wallpaperURL.lastPathComponent) has been downloaded.", comment: ""), style: .informational)
                    isDownloading = false
                    return
                }
                try? FileManager.default.copyItem(at: wallpaperURL, to: wallpapersDir.appendingPathComponent("\(wallpaperURL.lastPathComponent)"))
                
                Alert(title: NSLocalizedString("Download Success", comment: ""), message: NSLocalizedString("Wallpaper \(wallpaperURL.lastPathComponent) has been downloaded.", comment: ""), style: .informational)
                DatabaseManger.shared.addWallpaper(wallpaperURL.deletingPathExtension().lastPathComponent)
                NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
            } else {
                Alert(title: NSLocalizedString("Download Failed", comment: ""), message: NSLocalizedString("Failed to download wallpaper \(wallpaperURL.lastPathComponent).", comment: ""), style: .warning)
            }
            isDownloading = false
        }
    }
    
    private func generateThumbnail() {
        if wallpaperURL.pathExtension != "bundle" {
            Logger.error("\(wallpaperURL.path) is not a bundle.")
            return
        }
        
        let thumbnailUrl = wallpaperURL.appendingPathComponent("Preview/Preview.jpg")
        if let nsImage = NSImage(contentsOfFile: thumbnailUrl.path) {
            DispatchQueue.main.async {
                self.thumbnailImage = Image(nsImage: nsImage)
            }
        } else {
            Logger.error("\(thumbnailUrl.path) is not a valid image file.")
        }
    }
    
    private func debouncedAction(_ action: @escaping () -> Void) -> () -> Void {
        return {
            if !isButtonDisabled {
                isButtonDisabled = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
                    isButtonDisabled = false
                }
            }
        }
    }
}

struct DownloadingAlert: View {
    var body: some View {
        Text(NSLocalizedString("Wallpaper is downloading, please wait.", comment: ""))
            .font(.headline)
            .padding()
    }
}



#Preview {
    WallpaperHubView()
        .frame(width: 600, height: 400)
}
