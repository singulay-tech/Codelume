import SwiftUI
import AVKit
import AppKit

struct LocalWallpaperItemView: View {
    let item: WallpaperItem
    @State private var isHovering = false
    @State private var thumbnailImage: Image?
    @State private var isShowingPreview = false
    @State private var isShowingDetails = false
    @State private var isButtonDisabled = false
    @State private var isShowingScreenSelector = false
    @State private var selectedScreenId: String?
    @State private var screens = NSScreen.screens
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
                    VideoNameLabel(text: item.fileUrl.lastPathComponent)
                    Spacer()
                    VideoFloatButton(text: "Preview", action: debouncedAction { isShowingPreview = true })
                    VideoFloatButton(text: "Details", action: debouncedAction(showDetails))
                    VideoFloatButton(text: "Play", action: debouncedAction { isShowingScreenSelector = true })
                    VideoFloatButton(text: "Delete", color: .red, action: debouncedAction(deleteVideo))
                }
                .padding(8)
            }
        }
        .sheet(isPresented: $isShowingPreview) {
            ZStack(alignment: .topLeading) {
                VideoPreviewView(videoURL: item.fileUrl)
                VideoCloseButton(action: { isShowingPreview = false })
            }
        }
        .sheet(isPresented: $isShowingDetails) {
            ZStack(alignment: .topLeading) {
                DetailsView(item: item)
                    .padding(20)
                VideoCloseButton(action: { isShowingDetails = false })
            }
        }
        .sheet(isPresented: $isShowingScreenSelector) {
            ScreenSelectorView(screens: NSScreen.screens, onSelect: handleScreenSelection)
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
    
    private func fileURL(for relativePath: String) -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(relativePath)
    }
    
    private func showDetails() {
        isShowingDetails = true
    }
    
    private func generateThumbnail() {
        let asset = AVAsset(url: item.fileUrl)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        generator.generateCGImageAsynchronously(for: time) { cgImage, _, _ in
            if let cgImage = cgImage {
                DispatchQueue.main.async {
                    let nsImage = NSImage(cgImage: cgImage, size: .zero)
                    self.thumbnailImage = Image(nsImage: nsImage)
                }
            }
        }
    }
    
    private func playVideo() {
        let videoURL = item.fileUrl
        NotificationCenter.default.post(name: .playVideoUrlChanged, object: nil, userInfo: ["videoURL": videoURL])
    }
    
    private func handleScreenSelection(screen: NSScreen?) {
        guard let screen = screen else {
            isShowingScreenSelector = false
            return
        }
        
        let videoURL = item.fileUrl
        
        // 检查是否为"所有屏幕"选项
        if screen.identifier == "AllScreens" {
            // 发送不带屏幕ID的通知，让WindowController更新所有屏幕
            NotificationCenter.default.post(
                name: .playVideoUrlChanged,
                object: nil,
                userInfo: ["videoURL": videoURL]
            )
        } else {
            // 发送带屏幕ID的通知
            NotificationCenter.default.post(
                name: .playVideoUrlChanged,
                object: nil,
                userInfo: ["videoURL": videoURL, "screenIdentifier": screen.identifier]
            )
        }
        
        isShowingScreenSelector = false
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
    
    private func deleteVideo() {
        guard !DatabaseManger.shared.isUrlInScreenConfig(url: item.fileUrl) else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Cannot Delete", comment: "")
            alert.informativeText = NSLocalizedString("This video is currently being used by a screen and cannot be deleted.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.alertStyle = .warning
            alert.runModal()
            return
        }
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Delete this video?", comment: "")
        alert.informativeText = NSLocalizedString(
            "Non-program-built-in local video cannot be recovered after deletion and need to be redownloaded or imported.",
            comment: "")
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            DatabaseManger.shared.deleteLocalVideo(item: item)
            NotificationCenter.default.post(name: .refreshLocalVideoList, object: nil)
            Logger.info("Local video deleted successfully: \(item.fileUrl)")
        }
    }
}

// 屏幕选择器视图
struct ScreenSelectorView: View {
    let screens: [NSScreen]
    let onSelect: (NSScreen?) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Select Screen")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    onSelect(nil)
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    // 添加"所有屏幕"选项
                    AllScreensRow(onSelect: onSelect)
                    
                    ForEach(screens, id: \.identifier) {
                        screen in
                        ScreenRow(screen: screen, onSelect: onSelect)
                    }
                }
                .padding()
            }
        }
        .frame(width: 300, height: CGFloat(min(400, screens.count * 80 + 180))) // 增加高度以容纳"所有屏幕"选项
    }
}

// 所有屏幕选项行视图
struct AllScreensRow: View {
    let onSelect: (NSScreen?) -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("All Screens")
                    .font(.body)
                    .bold()
                Text("Display on all available screens")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "display.2")
                .foregroundColor(.blue)
        }
        .padding()
        .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            // 创建一个虚拟的NSScreen实例来表示"所有屏幕"
            let allScreensPlaceholder = AllScreensPlaceholder()
            onSelect(allScreensPlaceholder)
        }
    }
}

// 虚拟的NSScreen子类，用于表示"所有屏幕"选项
class AllScreensPlaceholder: NSScreen {
    override var localizedName: String {
        return "AllScreens"
    }
    
    override var frame: NSRect {
        return .zero
    }
    
    override class var main: NSScreen? {
        return nil
    }
    
    override var deviceDescription: [NSDeviceDescriptionKey : Any] {
        return [:]
    }
}

// 屏幕行项目视图
struct ScreenRow: View {
    let screen: NSScreen
    let onSelect: (NSScreen?) -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Screen \(screen.identifier)")
                    .font(.body)
                Text("\(Int(screen.frame.width))x\(Int(screen.frame.height))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if screen == NSScreen.main {
                Text("Main")
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onSelect(screen)
        }
    }
}

#Preview {
    LocalWallpaperItemView(item: WallpaperItem(
        id: UUID(),
        title: "Sample Video",
        fileUrl: Bundle.main.url(forResource: "codelume_0", withExtension: "mp4")!,
        resolution: "1920x1080",
        fileSize: 123456,
        codec: "H.264",
        duration: 60.0,
        creationDate: Date()
    ))
}
