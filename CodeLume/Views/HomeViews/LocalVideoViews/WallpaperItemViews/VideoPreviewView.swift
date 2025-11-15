import SwiftUI
import AVKit

struct VideoPreviewView: View {
    let videoURL: URL
    
    @AppStorage("volume") private var volume: Double = 1.0
    @AppStorage("mute") private var mute: Bool = false
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .frame(width: 1000, height: 563)
            .onAppear {
                player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                player.actionAtItemEnd = .none
                player.volume = Float(volume)
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
            .onChange(of: volume) { _, newValue in
                player.volume = Float(newValue)
            }
            .onChange(of: mute) { _, newValue in
                player.isMuted = false
            }
    }
}

#Preview {
    let videoURL = Bundle.main.url(forResource: "codelume_0", withExtension: "mp4")!
    VideoPreviewView(videoURL: videoURL)
}
