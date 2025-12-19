import SwiftUI
import AVKit
import CodelumeBundle

struct WallpaperPreviewView: View {
    let url: URL
    @State private var player = AVPlayer()
    @State private var videoURL: URL?
    @State private var errorMessage: String?
    private let defaultVolume: Float = 0.5
    
    var body: some View {
        Group {
            if let videoURL = videoURL {
                VideoPreviewView(videoURL: videoURL)
                    
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                Text("Loading...")
            }
        }
        .onAppear {
            extractWallpaperURL()
        }
    }
    
    private func extractWallpaperURL() {
        let wallpaper = VideoWallpaper()
        if !wallpaper.open(wallpaperUrl: url) {
            errorMessage = "Error opening wallpaper: \(url)"
            return
        }

        if let videoUrl = wallpaper.videoUrl {
            self.videoURL = videoUrl
        } else {
            errorMessage = "Invalid video url in wallpaper bundle"
            return
        }
    }
}

struct VideoPreviewView: View {
    let videoURL: URL
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .frame(width: 1000, height: 600)
            .onAppear {
                player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                player.actionAtItemEnd = .none
                player.volume = 0.3
                player.isMuted = false
                player.play()
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }
            .onDisappear {
                player.pause()
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            }
    }
}


#Preview {
    let wallpaperURL = Bundle.main.url(forResource: "thinking_cat", withExtension: "bundle")!
    WallpaperPreviewView(url: wallpaperURL)
}
