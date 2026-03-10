//
//  ScreenListItemView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/29.
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

#Preview {
//    ScreenListItemView()
}
