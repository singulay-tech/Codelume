import SwiftUI
import UniformTypeIdentifiers

struct ScreenSaverView: View {
    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Title(title: "Codelume Screen Saver")
                SectionTitle(title: "Screen Saver Introduction")
                DescriptionText(desc: "Screen savers originated in the CRT monitor era, primarily designed to prevent 'burn-in' caused by static images remaining on the screen for extended periods. This phenomenon occurs when electron beams continuously bombard the same phosphor areas, causing permanent physical damage. As technology evolved to LCD and OLED displays, screen savers transformed from mere hardware protection to versatile platforms that integrate security, energy management, information display, and personalized experiences.")
                DescriptionText(desc: "Codelume offers a dedicated screen saver module that allows users to set their current dynamic wallpapers as screen savers after downloading and installing it. This creates a seamless visual transition between active desktop environments and idle states, extending dynamic aesthetics throughout the entire device usage cycle while ensuring privacy security and maintaining a consistent immersive visual experience.")

                Spacer()
                
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
            }
            .aboutSectionCard()
            .padding()
            .frame(minWidth: 800, minHeight: 600)
    }
    
    func downloadScreensaver() {
        guard let saverURL = Bundle.main.url(forResource: "Codelume", withExtension: "saver") else {
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
                    try FileManager.default.copyItem(at: saverURL, to: destinationURL)
                    Logger.info("Screensaver saved successfully to: \(destinationURL.path)")
                    Alert(title: "Screensaver Saved")
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

