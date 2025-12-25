import SwiftUI
import Foundation
import AppKit

struct ScreenSaverView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("CodeLume Screen Saver")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screen Saver Introduction")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Screen savers originated in the CRT monitor era, primarily designed to prevent 'burn-in' caused by static images remaining on the screen for extended periods. This phenomenon occurs when electron beams continuously bombard the same phosphor areas, causing permanent physical damage. As technology evolved to LCD and OLED displays, screen savers transformed from mere hardware protection to versatile platforms that integrate security, energy management, information display, and personalized experiences.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    Text("CodeLume offers a dedicated screen saver module that allows users to set their current dynamic wallpapers as screen savers after downloading and installing it. This creates a seamless visual transition between active desktop environments and idle states, extending dynamic aesthetics throughout the entire device usage cycle while ensuring privacy security and maintaining a consistent immersive visual experience.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Spacer()
                    Button(action: downloadScreensaver) {
                        Text("Download Screen Saver")
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Installation Method")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("1. Click the download button to download the screen saver file to your desktop;")
                        Image("ScreenSaver_1")
                            .resizable()
                            .scaledToFit()
                        Text("2. Double-click the downloaded .saver file to install;")
                        Image("ScreenSaver_2")
                            .resizable()
                            .scaledToFit()
                        Text("3. Select your video file to set up;")
                        Image("ScreenSaver_3")
                            .resizable()
                            .scaledToFit()
                        Text("4. Click \"Preview\" to view the effect.")
                        Image("ScreenSaver_4")
                            .resizable()
                            .scaledToFit()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    ScreenSaverView()
        .frame(width: 600, height: 400)
}

