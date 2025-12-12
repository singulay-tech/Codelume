//
//  Untitled.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/12.
//

import SwiftUI
import AppKit

struct ScreenConfigurationDetailView: View {
    @ObservedObject var screenManager = ScreenManager.shared
    let configurationId: String
    
    // 动态获取最新的配置
    private var currentConfiguration: ScreenConfiguration? {
        screenManager.screenConfigurations.first(where: { $0.id == configurationId })
    }

    @State private var isPlaying: Bool
    @State private var volume: Double
    @State private var playbackType: PlaybackType
    @State private var videoFillMode: WallpaperFillMode
    
    init(configuration: ScreenConfiguration) {
        self.configurationId = configuration.id
        _isPlaying = State(initialValue: configuration.isPlaying)
        _volume = State(initialValue: configuration.volume)
        _playbackType = State(initialValue: configuration.playbackType)
        _videoFillMode = State(initialValue: configuration.videoFillMode)
    }
    
    var body: some View {
        if let configuration = currentConfiguration {
            VStack(alignment: .leading, spacing: 20) {
                ScreenBasicInfoView(configuration: configuration)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Playback Controls")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .foregroundColor(.accentColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading) {
                        Slider(value: $volume, in: 0...1, step: 0.01) {
                            Text("Volume:")
                        } minimumValueLabel: {
                            Image(systemName: "speaker.slash.fill")
                        } maximumValueLabel: {
                            Image(systemName: "speaker.3.fill")
                        }
                        .onChange(of: volume) {
                            updateVolume()
                        }
                    }
                    .frame(width: 250)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Content Configuration")
                    .font(.headline)
                
                HStack {
                    Text("Playback Type:")
                        .frame(width: 100, alignment: .trailing)
                    Text(playbackType.description)
                        .foregroundColor(.accentColor)
                }
                
                HStack {
                    Text("Fill Mode:")
                        .frame(width: 100, alignment: .trailing)
                    
                    Picker("", selection: $videoFillMode) {
                        ForEach(WallpaperFillMode.allCases, id: \.self) {
                            Text($0.description)
                        }
                    }
                    .onChange(of: videoFillMode) {
                        updateVideoFillMode()
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Content Path:")
                        .font(.subheadline)
                    
                    if let contentUrl = configuration.contentUrl {
                        Text(contentUrl.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    } else {
                        Text("Unset Content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Button("Select") {
                            selectContent()
                        }
                        .tint(.accentColor)
                        
                        Button("Clear") {
                            clearContent()
                        }
                        .tint(.accentColor)
                        .disabled(configuration.contentUrl == nil)
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
                .disabled(isScreenOnline)

                Button("Reset Configuration") {
                    resetConfiguration()
                }
                .tint(.accentColor)
            }
            
            Spacer()
        }
        .padding(20)
        .onChange(of: screenManager.screenConfigurations) { _ in
            // 当屏幕配置变化时，更新@State变量以保持与最新配置同步
            if let newConfig = currentConfiguration {
                self.isPlaying = newConfig.isPlaying
                self.volume = newConfig.volume
                self.playbackType = newConfig.playbackType
                self.videoFillMode = newConfig.videoFillMode
            }
        }
        .onChange(of: isPlaying) {
            // 当播放状态变化时，更新配置
            screenManager.updatePlaybackState(screenId: configurationId, isPlaying: isPlaying)
        }
        .onChange(of: volume) {
            // 当音量变化时，更新配置
            screenManager.updateVolume(screenId: configurationId, volume: volume)
        }
        .onChange(of: playbackType) {
            // 当播放类型变化时，更新配置
            screenManager.updatePlaybackType(screenId: configurationId, playbackType: playbackType)
        }
        .onChange(of: videoFillMode) {
            // 当填充模式变化时，更新配置
            screenManager.updateVideoFillMode(screenId: configurationId, fillMode: videoFillMode)
        }
    } else {
        // 当配置不存在时显示空视图
        EmptyConfigurationView()
    }
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        screenManager.updatePlaybackState(screenId: configurationId, isPlaying: isPlaying)
    }
    
    private func updateVolume() {
        screenManager.updateVolume(screenId: configurationId, volume: volume)
    }

    private func updateVideoFillMode() {
        screenManager.updateVideoFillMode(screenId: configurationId, fillMode: videoFillMode)
    }
    
    private func selectContent() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                screenManager.updateContentUrl(screenId: configurationId, contentUrl: url)
            }
        }
    }
    
    private func clearContent() {
        screenManager.updateContentUrl(screenId: configurationId, contentUrl: nil)
    }
    
    private var isScreenOnline: Bool {
        return currentConfiguration?.isConnected ?? false
    }
    
    private func resetConfiguration() {
        screenManager.resetScreenConfiguration(screenId: configurationId)
    
        isPlaying = true
        volume = 0.3
        videoFillMode = .fill
    }
    
    private func deleteConfiguration() {
        screenManager.deleteScreenConfiguration(screenId: configurationId)
    }
}

#Preview {
    let screenManager = ScreenManager.shared
    ScreenConfigurationDetailView(configuration: screenManager.screenConfigurations.first!)
        .frame(width: 600, height: 500)
}
