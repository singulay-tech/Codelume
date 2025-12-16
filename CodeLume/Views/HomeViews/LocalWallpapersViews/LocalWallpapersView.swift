import AVKit
import AppKit
import Foundation
import SwiftUI

struct LocalWallpapersView: View {
    @State private var wallpaperItems: [URL] = []
    
    var body: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(wallpaperItems, id: \.self) { url in
                    LocalWallpaperItemView(wallpaperURL: url)
                        .aspectRatio(16 / 9, contentMode: .fit)
                }
            }
            .padding()
        }
        .onAppear {
            loadLocalWallpapers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshLocalWallpaperList)) { _ in
            Logger.info("Received refresh local wallpapers notification.")
            loadLocalWallpapers()
        }
    }
    
    private func loadLocalWallpapers() {
        let wallpapers = DatabaseManger.shared.getAllWallpapers()
        Logger.info("load \(wallpapers.count) wallpapers.")
        
        guard let wallpapersSaveURL = getWallpaperSaveURL() else {
            Logger.error("Failed to get wallpapers save URL.")
            return
        }
        
        wallpaperItems.removeAll()
        
        for wallpaper in wallpapers {
            let wallpaperURL = wallpapersSaveURL.appendingPathComponent("\(wallpaper).bundle")
            wallpaperItems.append(wallpaperURL)
        }
    }
}

#Preview {
    LocalWallpapersView()
        .frame(width: 600, height: 400)
}

