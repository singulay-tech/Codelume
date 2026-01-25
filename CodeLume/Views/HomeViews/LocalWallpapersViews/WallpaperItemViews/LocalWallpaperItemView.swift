import SwiftUI
import AVKit
import AppKit
import CodelumeBundle

struct LocalWallpaperItemView: View {
    let wallpaperURL: URL
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
                    WallpaperNameLabel(text: wallpaperURL.lastPathComponent)
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
                WallpaperPreviewView(url: wallpaperURL)
                CloseButton(action: { isShowingPreview = false })
            }
        }
        .sheet(isPresented: $isShowingDetails) {
            ZStack(alignment: .topLeading) {
                DetailsView(wallpaperURL: wallpaperURL)
                    .padding(20)
                CloseButton(action: { isShowingDetails = false })
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
        // 确保wallpaperURL不为空且是bundle
        if wallpaperURL.pathExtension != "bundle" {
            Logger.error("无效的壁纸bundle URL: \(wallpaperURL.path)")
            return
        }
        
        let thumbnailUrl = wallpaperURL.appendingPathComponent("Preview/Preview.jpg")
        // 加载预览图
        if let nsImage = NSImage(contentsOfFile: thumbnailUrl.path) {
            DispatchQueue.main.async {
                self.thumbnailImage = Image(nsImage: nsImage)
            }
        } else {
            Logger.error("无法加载预览图: \(thumbnailUrl.path)")
        }
    }
    
    private func handleScreenSelection(screen: NSScreen?) {
        guard let screen = screen else {
            isShowingScreenSelector = false
            return
        }
        
        let videoURL = wallpaperURL
        
        // 检查是否为"所有屏幕"选项
        if screen.identifier == "AllScreens" {
            // 发送不带屏幕ID的通知，让WindowController更新所有屏幕
            ScreenManager.shared.updateAllScreensWallpaper(wallpaperURL: videoURL)
            NotificationCenter.default.post(name: .wallpaperBundleChanged, object: nil, userInfo: [:])
            
        } else {
            ScreenManager.shared.updateScreenWallpaper(screenId: screen.identifier, wallpaperURL: videoURL)
            // 发送带屏幕ID的通知
            NotificationCenter.default.post(name: .wallpaperBundleChanged, object: nil, userInfo: ["id": screen.identifier])
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
        // 获取当前所有的屏幕配置，检查当前url是否正在使用
        let screenConfigs = ScreenManager.shared.screenConfigurations
        
        // 检查当前url是否正在使用
        let isUsed = screenConfigs.contains { $0.wallpaperUrl == wallpaperURL }
        
        // 如果当前url正在使用，提示用户
        if isUsed {
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
            let wallpaperName = wallpaperURL.deletingPathExtension().lastPathComponent
            DatabaseManger.shared.deleteWallpaper(by: wallpaperName)
            NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
            Logger.info("Local wallpaper deleted successfully: \(wallpaperURL)")
        }
    }
}

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
                    AllScreensRow(onSelect: onSelect)
                    
                    ForEach(screens, id: \.identifier) {
                        screen in
                        ScreenRow(screen: screen, onSelect: onSelect)
                    }
                }
                .padding()
            }
        }
        .frame(width: 300, height: CGFloat(min(400, screens.count * 80 + 180)))
    }
}

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
            let allScreensPlaceholder = AllScreensPlaceholder()
            onSelect(allScreensPlaceholder)
        }
    }
}

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
    let bundleURL = Bundle.main.url(forResource: "DefaultBundle", withExtension: "bundle")!
    LocalWallpaperItemView(wallpaperURL: bundleURL)
}
