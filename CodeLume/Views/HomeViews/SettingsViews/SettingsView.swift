import SwiftUI

struct SettingsView: View {
    @State private var selectedTab = 1
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                GeneralSettingsView().tabItem {
                    Label("General Settings", systemImage: "gear")
                }.tag(1)
                PlaybackSettingsView().tabItem {
                    Label("Playback Settings", systemImage: "play.circle")
                }.tag(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 0)
        .padding(.bottom, 20)
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    SettingsView()
}
