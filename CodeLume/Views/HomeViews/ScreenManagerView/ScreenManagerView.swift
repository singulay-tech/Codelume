//
//  EmptyConfigurationView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/29.
//

import SwiftUI
import AppKit

struct ScreenManagerView: View {
    @ObservedObject var screenManager = ScreenManager.shared
    var body: some View {
        HStack() {
            VStack(alignment: .center) {
                List(selection: $screenManager.selectedScreenId) {
                    ForEach(screenManager.screenConfigurations) { config in
                        ScreenListItemView(configuration: config)
                            .tag(config.id)
                    }
                }
                .scrollContentBackground(.hidden)
                ScreenStatisticsView(
                    totalScreens: screenManager.screenConfigurations.count,
                    connectedScreens: screenManager.getCurrentScreenCount()
                )
                    .padding(.bottom, 8)
            }
            .frame(width: 250)
            
            Divider()
            
            if let selectedId = screenManager.selectedScreenId {
                ScreenConfigurationDetailView(screenId: selectedId)
            } else {
                EmptyConfigurationView()
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

#Preview {
    ScreenManagerView()
}
