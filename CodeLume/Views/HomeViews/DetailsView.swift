import SwiftUI
import CodelumeBundle
struct DetailsView: View {
    var wallpaperURL: URL
    @State private var wallpaperBundele: VideoWallpaper?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            infoRow("FileName", wallpaperURL.lastPathComponent)
            infoRow("WallpaperName", wallpaperBundele?.bundleInfo.name ?? wallpaperURL.deletingPathExtension().lastPathComponent)
            infoRow("Description", wallpaperBundele?.bundleInfo.description ?? "")
            infoRow("Author", wallpaperBundele?.bundleInfo.author ?? "Unknown")
            infoRow("Email", wallpaperBundele?.bundleInfo.email ?? "Unknown")
            infoRow("Version", wallpaperBundele?.bundleInfo.version ?? "Unknown")
            
            Divider()
            
            infoRow("Width", String(wallpaperBundele?.videoInfo?.width ?? 0))
            infoRow("Height", String(wallpaperBundele?.videoInfo?.height ?? 0))
            infoRow("Duration(s)", String(wallpaperBundele?.videoInfo?.duration ?? 0))
            infoRow("Size(MB)", String(wallpaperBundele?.videoInfo?.size ?? 0))
            infoRow("Format", wallpaperBundele?.videoInfo?.format ?? "")
            infoRow("Loop", String(wallpaperBundele?.videoInfo?.loop ?? false))
            
            
        }
        .onAppear {
            Task {
                Task {
                    wallpaperBundele = VideoWallpaper()
                    _ = wallpaperBundele?.open(wallpaperUrl: wallpaperURL)
                }
            }
            
        }
        .padding()
    }
   
   @ViewBuilder
   private func infoRow(_ label: String, _ value: String) -> some View {
       HStack {
           Text("\(NSLocalizedString(label, comment: "")):").bold()
           Text(value)
       }
   }
}

#Preview {
    let bundleURL = Bundle.main.url(forResource: "thinking_cat", withExtension: "bundle")!
    DetailsView(wallpaperURL: bundleURL)
        .frame(width:400, height: 360)
}
