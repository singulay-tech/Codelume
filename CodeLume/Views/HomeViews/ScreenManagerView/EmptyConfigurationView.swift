//
//  EmptyConfigurationView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/29.
//

import SwiftUI

struct EmptyConfigurationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "display.2")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Please select a screen to configure")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("From the list on the left, select a screen to view and edit its configuration information")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyConfigurationView()
}
