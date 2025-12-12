//
//  ScreenManagerView.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/11.
//

import SwiftUI
import AppKit

struct ScreenManagerView: View {
    @ObservedObject var screenManager = ScreenManager.shared
    @State private var selectedConfiguration: ScreenConfiguration?
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                List(selection: $selectedConfiguration) {
                    ForEach(screenManager.screenConfigurations) { config in
                        ScreenListItemView(configuration: config)
                            .tag(config)
                    }
                }
                .frame(width: 250)
                ScreenStatisticsView()
                    .padding(.bottom, 8)
            }
            
            Divider()
            
            if let selectedConfig = selectedConfiguration {
                ScreenConfigurationDetailView(configuration: selectedConfig)
            } else {
                EmptyConfigurationView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ScreenManagerView()
}
