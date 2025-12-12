import AVKit
import AppKit
import Foundation
import SwiftUI

struct LocalVideoView: View {
    @State private var videoItems: [WallpaperItem] = []
    
    var body: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(videoItems, id: \.id) { item in
                    LocalWallpaperItemView(item: item)
                    .aspectRatio(16 / 9, contentMode: .fit)
                }
            }
            .padding()
        }
        .onAppear {
            loadVideoItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshLocalWallpaperList)) { _ in
            Logger.info("start load video items from database.")
            loadVideoItems()
        }
    }
    
    private func loadVideoItems() {
//        videoItems = DatabaseManger.shared.getAllLocalVideos()
    }
    
    private func fileURL(for relativePath: String) -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(relativePath)
    }
}

#Preview {
    LocalVideoView()
        .frame(width: 600, height: 400)
}

