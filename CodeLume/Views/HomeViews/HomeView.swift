import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            VStack {
                List {
//                    NavigationLink("Playing", destination: PlayingView()
//                        .navigationTitle("Playing"))
                    
                    NavigationLink("LocalVideos", destination: LocalVideoView()
                        .navigationTitle("LocalVideos"))
                    NavigationLink("Screen Saver", destination: ScreenSaverView()
                        .navigationTitle("Screen Saver"))
                    NavigationLink("About", destination: AboutView()
                        .navigationTitle("About"))
                }
                .listStyle(.sidebar)
                .frame(minWidth: 220)
                
                Spacer()
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
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
