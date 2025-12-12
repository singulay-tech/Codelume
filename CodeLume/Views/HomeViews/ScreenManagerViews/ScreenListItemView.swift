//
//  ScreenListItemView.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/12.
//

import SwiftUI

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
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                        } else {
                            Image(systemName: "pause.circle.fill")
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

            Text(getScreenResolution(for: configuration.id))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
    }
    
    private func getScreenResolution(for screenId: String) -> String {
        if let screen = NSScreen.screens.first(where: { $0.identifier == screenId }) {
            return ScreenManager.shared.getScreenResolution(screen: screen)
        }
        return "Unknown Resolution"
    }
}

#Preview() {
    let screenManager = ScreenManager.shared
    ScreenListItemView(configuration: screenManager.screenConfigurations.first!)
}
