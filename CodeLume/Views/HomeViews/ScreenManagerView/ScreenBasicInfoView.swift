//
//  ScreenBasicInfoView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/29.
//

import SwiftUI
import AppKit

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
                Text("Main Screen:")
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
                Text(configuration.physicalResolution)
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
            let screenFrame = screen.frame
            let width = Int(screenFrame.width)
            let height = Int(screenFrame.height)
            return "\(width) x \(height)"
        }
        return "Unknown Resolution"
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
    ScreenBasicInfoView(configuration: ScreenConfiguration(id: "Preview"))
}
