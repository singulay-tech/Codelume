import SwiftUI
import UniformTypeIdentifiers

struct ScreenSaverView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Codelume Screen Saver")
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
                    Text("Codelume offers a dedicated screen saver module that allows users to set their current dynamic wallpapers as screen savers after downloading and installing it. This creates a seamless visual transition between active desktop environments and idle states, extending dynamic aesthetics throughout the entire device usage cycle while ensuring privacy security and maintaining a consistent immersive visual experience.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Spacer()
                    Button(action: downloadScreensaver) {
                        Text("Download Screen Saver")
                            .padding(6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Link("View installation instructions on GitHub.",
                         destination: URL(string: "https://github.com/guang-zi-yu/CodelumeSaver.git")!)
                    .font(.caption)
                    .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.top, 5)
                
                Spacer()
                    .frame(height: 40)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    func downloadScreensaver() {
        guard let saverURL = Bundle.main.url(forResource: "CodelumeSaver", withExtension: "saver") else {
            Logger.error("Failed to find screensaver in bundle")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = NSLocalizedString("Save Screen Saver", comment: "")
        savePanel.nameFieldStringValue = "Codelume.saver"
        savePanel.allowedContentTypes = [UTType(filenameExtension: "saver") ?? .item]
        
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        savePanel.directoryURL = desktopURL
        
        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.copyItem(at: saverURL, to: destinationURL)
                    Logger.info("Screensaver saved successfully to: \(destinationURL.path)")

                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("Screensaver Saved", comment: "")
                        alert.informativeText = NSLocalizedString("Screensaver saved successfully!", comment: "")
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                        alert.runModal()
                    }
                } catch {
                    Logger.error("Failed to save screensaver: \(error)")
                }
            }
        }
    }
}

#Preview {
    ScreenSaverView()
        .frame(width: 600, height: 400)
}

