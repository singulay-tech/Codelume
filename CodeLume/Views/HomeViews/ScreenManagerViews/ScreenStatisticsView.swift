//
//  ScreenStatisticsView.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/12.
//

import SwiftUI

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
        .background(Color.gray.opacity(0.1))
        .cornerRadius(24)
    }
}

#Preview {
    ScreenStatisticsView()
        .frame(width: 400, height: 150)
}
