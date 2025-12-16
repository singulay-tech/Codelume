import SwiftUI
import AVKit

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
        let codelumeJsonUrl = url.appendingPathComponent("codelume.json")
        do {
            let codelumeJsonData = try Data(contentsOf: codelumeJsonUrl)
            let codelumeJson = try JSONSerialization.jsonObject(with: codelumeJsonData, options: []) as? [String: Any]
            
            if let wallpaperType = codelumeJson?["wallpaperType"] as? String, wallpaperType == "Video" {
                if let videoConfigPath = codelumeJson?["video"] as? String {
                    let videoConfigUrl = url.appendingPathComponent(videoConfigPath)
                    
                    let videoConfigData = try Data(contentsOf: videoConfigUrl)
                    let videoConfig = try JSONSerialization.jsonObject(with: videoConfigData, options: []) as? [String: Any]
                    
                    if let videoPath = videoConfig?["url"] as? String {
                        self.videoURL = url.appendingPathComponent(videoPath)
                    } else {
                        errorMessage = "Invalid video url in video.json"
                    }
                } else {
                    errorMessage = "Invalid video config path in codelume.json"
                }
            } else {
                errorMessage = "Wallpaper type is not Video"
            }
        } catch {
            errorMessage = "Error loading wallpaper: \(error.localizedDescription)"
        }
    }
}

struct VideoPreviewView: View {
    let videoURL: URL
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .frame(width: 1000, height: 563)
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
