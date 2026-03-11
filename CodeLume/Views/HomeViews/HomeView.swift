import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            GlowOrbs()
            AuroraView()
            NavigationSplitView {
                VStack {
                    List {
                        NavigationLink(destination: ScreenManagerView()
                            .navigationTitle("")) {
                                Label("ScreenManager", systemImage: "display.2")
                            }
                        NavigationLink(destination: LocalWallpapersView()
                            .navigationTitle("")) {
                                Label("LocalWallpaper", systemImage: "photo.on.rectangle")
                            }
                        NavigationLink(destination: WallpaperHubView()
                            .navigationTitle("")) {
                                Label("Wallpaper Hub", systemImage: "icloud.and.arrow.down")
                            }
                        NavigationLink(destination: ScreenSaverView()
                            .navigationTitle("")) {
                                Label("Screen Saver", systemImage: "sparkles")
                            }
                        NavigationLink(destination: SettingsView()
                            .navigationTitle("")) {
                                Label("Preferences", systemImage: "gear")
                            }
                        NavigationLink(destination: AboutView()
                            .navigationTitle("")) {
                                Label("About", systemImage: "info.circle")
                            }
                    }
                    .listStyle(.sidebar)
                    .frame(width: 220)
                    
                    Spacer()
                    
                    UserAuthView()
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("Version \(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(5)
                    }
                }
                .frame(width: 220)
                .navigationSplitViewColumnWidth(min: 220, ideal: 220, max: 220)
            } detail: {
                LocalWallpapersView()
                    .navigationTitle("")
            }
        }
    }
}

#Preview {
    HomeView()
}
