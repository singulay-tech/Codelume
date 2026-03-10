//
//  ScreenConfigurationDetailView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/29.
//

import SwiftUI

struct ScreenConfigurationDetailView: View {
    @ObservedObject var screenManager = ScreenManager.shared
    let screenId: String
    
    var body: some View {
        Group {
            if let cfg = screenManager.getScreenConfiguration(screenId: screenId) {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenBasicInfoView(configuration: cfg)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Playback Controls")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Button(action: togglePlayback) {
                                Image(systemName: cfg.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.accentColor)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Slider(value: Binding<Double>(
                                get: { cfg.volume },
                                set: { new in
                                    screenManager.updateVolume(screenId: screenId, volume: new)
                                }
                            ), in: 0...1, step: 0.1) {
                                Text("Volume:")
                            } minimumValueLabel: {
                                Image(systemName: "speaker.slash.fill")
                            } maximumValueLabel: {
                                Image(systemName: "speaker.3.fill")
                            }
                            .frame(width: 250)

                            Toggle(isOn: Binding<Bool>(
                                get: { cfg.isMuted },
                                set: { new in
                                    screenManager.updateMuteStatus(screenId: screenId, status: new)
                                }
                            )) {
                                Text("Muted")
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
                            Text(cfg.playbackType.description)
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
                            
                            if let contentUrl = cfg.wallpaperUrl {
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
            } else {
                EmptyConfigurationView()
            }
        }
    }
    
    
    private func togglePlayback() {
        if let cfg = screenManager.getScreenConfiguration(screenId: screenId) {
            screenManager.updatePlaybackState(screenId: screenId, isPlaying: !cfg.isPlaying)
        }
    }
    
    private func resetConfiguration() {
        screenManager.resetScreenConfiguration(screenId: screenId)
        Alert(title: "Reset Success", message: "Screen configuration has been reset.")
    }
    
    private func deleteConfiguration() {
        if let config = screenManager.getScreenConfiguration(screenId: screenId), config.isConnected {
            Alert(title: "Delete Failed", message: "Screen is connected. Please disconnect it first.")
            return
        }
        screenManager.deleteScreenConfiguration(screenId: screenId)
        Alert(title: "Delete Success")
    }
    
}

#Preview {
    ScreenConfigurationDetailView(screenId: "Preview")
}
