import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            VStack {
                List {
                    NavigationLink(destination: LocalVideoView()
                        .navigationTitle("LocalVideos")) {
                        Label("LocalVideos", systemImage: "film")
                    }
                    NavigationLink(destination: ScreenSaverView()
                        .navigationTitle("Screen Saver")) {
                        Label("Screen Saver", systemImage: "desktopcomputer")
                    }
                    NavigationLink(destination: SettingsView()
                        .navigationTitle("Preferences")) {
                        Label("Preferences", systemImage: "gear")
                    }
                    NavigationLink(destination: AboutView()
                        .navigationTitle("About")) {
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
                
                Text("© 2025 CodeLume. All rights reserved.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
        } detail: {
            LocalVideoView()
                .navigationTitle("LocalVideos")
        }
        .presentedWindowStyle(.automatic)
    }
}

#Preview {
    HomeView()
}
