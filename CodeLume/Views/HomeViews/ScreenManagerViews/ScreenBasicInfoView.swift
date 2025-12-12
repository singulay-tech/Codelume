//
//  ScreenBasicInfoView.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/12.
//

import SwiftUI

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
                Text("Is Main Screen:")
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
                Text(getPhysicalScreenResolution(for: configuration.id))
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
    
    private func getPhysicalScreenResolution(for screenId: String) -> String {
        if let screen = NSScreen.screens.first(where: { $0.identifier == screenId }) {
            return ScreenManager.shared.getPhysicalScreenResolution(screen: screen)
        }
        return "Unknown Physical Resolution"
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
    let screenManager = ScreenManager.shared
    ScreenBasicInfoView(configuration: screenManager.screenConfigurations.first!)
        .frame(width: 300, height: 150)
}
