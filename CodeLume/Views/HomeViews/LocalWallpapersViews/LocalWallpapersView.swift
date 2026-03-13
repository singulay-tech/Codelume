import AppKit
import Foundation
import SwiftUI

struct LocalWallpapersView: View {
    @State private var wallpaperItems: [URL] = []
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        Group {
            ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(wallpaperItems, id: \.self) { url in
                    LocalWallpaperHubCard(wallpaperURL: url)
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
        .frame(minWidth: 800, minHeight: 600)
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

private struct LocalWallpaperHubCard: View {
    let wallpaperURL: URL
    @State private var isShowingPreview = false
    @State private var isShowingScreenSelector = false

    private var wallpaperInfoPlist: [String: Any]? {
        let infoPlistURL = wallpaperURL.appendingPathComponent("Info.plist")

        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }

        return plist
    }

    private var wallpaperDisplayName: String {
        if let plist = wallpaperInfoPlist {
            if let displayName = plist["name"] as? String,
               !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return displayName
            }

            if let bundleName = plist["CFBundleName"] as? String,
               !bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return bundleName
            }
        }

        return wallpaperURL.deletingPathExtension().lastPathComponent
    }

    private var wallpaperType: String {
        if let type = wallpaperInfoPlist?["type"] as? String {
            return type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        return ""
    }

    private var wallpaperDescription: String {
        if let description = wallpaperInfoPlist?["description"] as? String,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        return "Stored in local wallpaper bundles."
    }

    private var wallpaperVideoInfo: WallpaperVideoInfoTable? {
        guard wallpaperType == "video" else { return nil }

        let videoPlistURL = wallpaperURL.appendingPathComponent("Video/Video.plist")

        guard let plistData = try? Data(contentsOf: videoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let width = plist["width"] as? Int,
              let height = plist["height"] as? Int,
              let duration = plist["duration"] as? Int,
              let format = plist["format"] as? String,
              let loop = plist["loop"] as? Bool,
              let isEncrypted = plist["encrypted"] as? Bool else {
            return nil
        }

        let sizeValue = (plist["size"] as? NSNumber)?.decimalValue ?? .zero

        return WallpaperVideoInfoTable(
            wallpaperId: UUID(),
            width: width,
            height: height,
            sizeMB: sizeValue,
            duration: duration,
            format: format,
            loop: loop,
            isEncrypted: isEncrypted
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LocalBundleStaticPreview(bundleURL: wallpaperURL)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Text(wallpaperDisplayName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()
            }

            if let wallpaperVideoInfo {
                WallpaperVideoInfoInline(info: wallpaperVideoInfo, isLoading: false)
            } else {
                Text("")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text(wallpaperDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

            HStack(spacing: 8) {
                Spacer()

                Button {
                    isShowingPreview = true
                } label: {
                    Label("Preview", systemImage: "eye")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    deleteVideo()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)

                Button {
                    isShowingScreenSelector = true
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .sheet(isPresented: $isShowingPreview) {
            WallpaperPreviewView(url: wallpaperURL)
        }
        .sheet(isPresented: $isShowingScreenSelector) {
            ScreenSelectorView(screens: NSScreen.screens, onSelect: handleScreenSelection)
        }
    }

    private func handleScreenSelection(screen: NSScreen?) {
        guard let screen = screen else {
            isShowingScreenSelector = false
            return
        }

        if screen.identifier == "AllScreens" {
            ScreenManager.shared.updateAllScreensWallpaper(wallpaperURL: wallpaperURL)
            NotificationCenter.default.post(name: .wallpaperBundleChanged, object: nil, userInfo: [:])
        } else {
            ScreenManager.shared.updateScreenWallpaper(screenId: screen.identifier, wallpaperURL: wallpaperURL)
            NotificationCenter.default.post(name: .wallpaperBundleChanged, object: nil, userInfo: ["id": screen.identifier])
        }

        isShowingScreenSelector = false
    }

    private func deleteVideo() {
        let screenConfigs = ScreenManager.shared.screenConfigurations
        let isUsed = screenConfigs.contains { $0.wallpaperUrl == wallpaperURL }

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

private struct LocalBundleStaticPreview: View {
    let bundleURL: URL
    @State private var previewImage: Image?

    var body: some View {
        ZStack {
            if let previewImage {
                previewImage
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            loadPreviewImage()
        }
    }

    private func loadPreviewImage() {
        let pngURL = bundleURL.appendingPathComponent("Preview/Preview.png")
        let jpgURL = bundleURL.appendingPathComponent("Preview/Preview.jpg")

        let imageURL: URL
        if FileManager.default.fileExists(atPath: pngURL.path) {
            imageURL = pngURL
        } else {
            imageURL = jpgURL
        }

        guard let nsImage = NSImage(contentsOf: imageURL) else {
            return
        }
        previewImage = Image(nsImage: nsImage)
    }
}

#Preview {
    LocalWallpapersView()
}

