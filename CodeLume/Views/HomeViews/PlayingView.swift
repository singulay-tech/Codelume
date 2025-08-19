//
//  PlayingViews.swift
//  codelume-app
//
//  Created by lyke on 2025/8/13.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PlayingView: View {
    @StateObject private var viewModel = ScreenPlaybackViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screen Management")
                .font(.title)
                .fontWeight(.bold)

            // 屏幕列表
            VStack(alignment: .leading, spacing: 10) {
                Text("Available Screens:")
                    .font(.headline)

                Picker("Select Screen", selection: $viewModel.selectedScreen) {
                    ForEach(viewModel.screens, id: \.self) {
                        Text("\($0.localizedName) (\($0.frame.width)x\($0.frame.height))")
                    }
                }
                .onChange(of: viewModel.selectedScreen) { oldValue, newValue in
                    if let screen = newValue {
                        viewModel.loadScreenConfiguration(screen: screen)
                    }
                }
            }

            // 播放设置
            VStack(alignment: .leading, spacing: 10) {
                Text("Playback Settings:")
                    .font(.headline)

                // 播放类型
                HStack {
                    Text("Playback Type:")
                        .frame(width: 100, alignment: .leading)
                    Picker("Playback Type", selection: $viewModel.selectedPlaybackType) {
                        Text("Video").tag(PlaybackType.video)
                        Text("SpriteKit").tag(PlaybackType.sprite)
                        Text("SceneKit").tag(PlaybackType.scene)
                    }
                    .frame(width: 200)
                }

                // 视频文件路径
                if viewModel.selectedPlaybackType == .video {
                    HStack {
                        Text("File Path:")
                            .frame(width: 100, alignment: .leading)
                        TextField("Enter file path", text: $viewModel.contentPath)
                            .frame(width: 300)
                        Button("Browse") {
                            viewModel.selectFile()
                        }
                    }
                }

                // 音量控制
                HStack {
                    Text("Volume:")
                        .frame(width: 100, alignment: .leading)
                    Slider(
                        value: $viewModel.volume,
                        in: 0...1,
                        step: 0.1
                    )
                    Text(String(format: "%.1f", viewModel.volume))
                        .frame(width: 40)
                }

                // 播放控制
                HStack {
                    Text("Playback Status:")
                        .frame(width: 100, alignment: .leading)
                    Toggle("Playing", isOn: $viewModel.isPlaying)
                }
            }

            // 更新按钮
            Button("Update Configuration") {
                viewModel.updateScreenConfiguration()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

#Preview {
    PlayingView()
}
