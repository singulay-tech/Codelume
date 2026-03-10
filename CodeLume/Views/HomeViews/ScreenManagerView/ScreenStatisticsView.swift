//
//  ScreenStatisticsView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/29.
//

import SwiftUI

struct ScreenStatisticsView: View {
    let totalScreens: Int
    let connectedScreens: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Screen Statistics")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack {
                    Text("\(totalScreens)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Screens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(connectedScreens)")
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

#Preview {
    ScreenStatisticsView(totalScreens: 2, connectedScreens: 1)
}
