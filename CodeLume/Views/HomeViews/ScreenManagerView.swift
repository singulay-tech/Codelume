import SwiftUI
import AppKit

struct ScreenManagerView: View {
    @ObservedObject var screenManager = ScreenManager.shared
    @State private var selectedConfiguration: ScreenConfiguration?
    
    var body: some View {
        HStack() {
            VStack(alignment: .center) {
                List(selection: $selectedConfiguration) {
                    ForEach(screenManager.screenConfigurations) { config in
                        ScreenListItemView(configuration: config)
                            .tag(config)
                    }
                }
                .scrollContentBackground(.hidden)
                ScreenStatisticsView()
                    .padding(.bottom, 8)
            }
            .frame(width: 250)
            
            Divider()
            
            if let selectedConfig = selectedConfiguration {
                ScreenConfigurationDetailView(currentConfiguration: selectedConfig)
                    .id(selectedConfig.id)
            } else {
                EmptyConfigurationView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshScreenManagerView)) { _ in
            selectedConfiguration = nil
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

struct ScreenListItemView: View {
    let configuration: ScreenConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: configuration.isMainScreen ? "desktopcomputer" : "display")
                    .foregroundColor(configuration.isConnected ? .accentColor : .secondary)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text(configuration.id)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text(configuration.isMainScreen ? "Main Screen" : "Secondary Screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if configuration.isPlaying {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                Text(configuration.playbackType.rawValue.capitalized)
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(14)
            }
        }
        .padding(8)
    }
}

struct EmptyConfigurationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "display.2")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Please select a screen to configure")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("From the list on the left, select a screen to view and edit its configuration information")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScreenStatisticsView: View {
    @ObservedObject var screenManager = ScreenManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Screen Statistics")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack {
                    Text("\(screenManager.screenConfigurations.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Screens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(screenManager.getCurrentScreenCount())")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .cornerRadius(24)
    }
}

struct ScreenConfigurationDetailView: View {
    @ObservedObject var screenManager = ScreenManager.shared
    @State var  currentConfiguration: ScreenConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenBasicInfoView(configuration: currentConfiguration)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Playback Controls")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button(action: togglePlayback) {
                        Image(systemName: currentConfiguration.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .foregroundColor(.accentColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Slider(value: $currentConfiguration.volume, in: 0...1, step: 0.1) {
                        Text("Volume:")
                    } minimumValueLabel: {
                        Image(systemName: "speaker.slash.fill")
                    } maximumValueLabel: {
                        Image(systemName: "speaker.3.fill")
                    }
                    .frame(width: 250)
                    .onChange(of: currentConfiguration.volume) { oldValue, newValue in
                        print("new volume: \(newValue)")
                        screenManager.updateVolume(screenId: currentConfiguration.id, volume: newValue)
                    }
                    
                    Toggle(isOn: $currentConfiguration.isMuted) {
                        Text("Muted")
                    }
                    .onChange(of: currentConfiguration.isMuted) { oldValue, newValue in
                        screenManager.updateMuteStatus(screenId: currentConfiguration.id, status: newValue)
                    }
                    
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Wallpaper Configuration")
                    .font(.headline)
                
                HStack {
                    Text("Playback Type:")
                        .frame(width: 150, alignment: .trailing)
                    Text(currentConfiguration.playbackType.description)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        .frame(width: 300,alignment: .leading)
                }
                HStack {
                    Text("Wallpaper bundle:")
                        .frame(width: 150, alignment: .trailing)
                    
                    if let contentUrl = currentConfiguration.wallpaperUrl {
                        Text(contentUrl.lastPathComponent)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                            .frame(width: 300, alignment: .leading)
                    } else {
                        Text("Unset wallpaper bundle")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                            .frame(width: 300, alignment: .leading)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Delete Configuration") {
                    deleteConfiguration()
                }
                .foregroundColor(.red)
                
                Button("Reset Configuration") {
                    resetConfiguration()
                }
                .tint(.accentColor)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private func togglePlayback() {
        currentConfiguration.isPlaying.toggle()
        screenManager.updatePlaybackState(screenId: currentConfiguration.id, isPlaying: currentConfiguration.isPlaying)
    }
    
    private var isScreenOnline: Bool {
        return currentConfiguration.isConnected
    }
    
    private func resetConfiguration() {
        screenManager.resetScreenConfiguration(screenId: currentConfiguration.id)
        Alert(title: NSLocalizedString("Reset Success", comment: ""), message: NSLocalizedString("Screen configuration has been reset.", comment: ""), style: .informational)
        NotificationCenter.default.post(name: .refreshScreenManagerView, object: nil)
    }
    
    private func deleteConfiguration() {
        if currentConfiguration.isConnected {
            Alert(title: NSLocalizedString("Delete Failed", comment: ""), message: NSLocalizedString("Screen is connected. Please disconnect it first.", comment: ""), style: .warning)
            return
        }
        screenManager.deleteScreenConfiguration(screenId: currentConfiguration.id)
        Alert(title: NSLocalizedString("Delete Success", comment: ""), message: NSLocalizedString("Screen configuration has been deleted.", comment: ""), style: .informational)
        NotificationCenter.default.post(name: .refreshScreenManagerView, object: nil)
    }
}

struct ScreenBasicInfoView: View {
    let configuration: ScreenConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screen Information")
                .font(.headline)
            
            HStack {
                Text("Screen ID:")
                    .frame(width: 100, alignment: .trailing)
                Text(configuration.id)
                    .font(.monospaced(.body)())
            }
            
            HStack {
                Text("Main Screen:")
                    .frame(width: 100, alignment: .trailing)
                Text(configuration.isMainScreen ? "Yes" : "No")
            }
            
            HStack {
                Text("Resolution:")
                    .frame(width: 100, alignment: .trailing)
                Text(getScreenResolution(for: configuration.id))
            }
            
            HStack {
                Text("Physical Resolution:")
                    .frame(width: 100, alignment: .trailing)
                Text(configuration.physicalResolution)
            }
            
            HStack {
                Text("Screen Status:")
                    .frame(width: 100, alignment: .trailing)
                Text(getScreenStatus(for: configuration.id))
            }
        }
    }
    
    private func getScreenResolution(for screenId: String) -> String {
        if let screen = NSScreen.screens.first(where: { $0.identifier == screenId }) {
            return ScreenManager.shared.getScreenResolution(screen: screen)
        }
        return "Unknown Resolution"
    }
    
    private func getScreenStatus(for screenId: String) -> String {
        if NSScreen.screens.contains(where: { $0.identifier == screenId }) {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }
}

#Preview {
    ScreenManagerView()
}
