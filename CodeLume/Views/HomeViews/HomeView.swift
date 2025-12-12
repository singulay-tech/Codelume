import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            VStack {
                List {
                    NavigationLink(destination: ScreenManagerView()
                        .navigationTitle("")) {
                        Label("ScreenManager", systemImage: "display.2")
                    }
                    NavigationLink(destination: LocalVideoView()
                        .navigationTitle("")) {
                        Label("LocalVideos", systemImage: "film")
                    }
                    NavigationLink(destination: ScreenSaverView()
                        .navigationTitle("")) {
                        Label("Screen Saver", systemImage: "desktopcomputer")
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
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } detail: {
            LocalVideoView()
                .navigationTitle("")
        }
        .presentedWindowStyle(.automatic)
    }
}

#Preview {
    HomeView()
}
