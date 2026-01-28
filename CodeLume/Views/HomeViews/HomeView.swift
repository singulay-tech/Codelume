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
                    .frame(minWidth: 220)
                    
                    Spacer()
                    
//                    UserAuthView()
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("Version \(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(5)
                    }
                }
            } detail: {
                LocalWallpapersView()
                    .navigationTitle("")
            }
        }
        .frame(minWidth: 1050, minHeight: 600)
    }
}

#Preview {
    HomeView()
}
