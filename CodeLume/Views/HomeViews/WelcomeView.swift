import SwiftUI

struct WelcomeView: View {
    @State private var showAgain = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            GlowOrbs()
            AuroraView()
            VStack(spacing: 10) {
                Image("Welcome")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 550, height: 35)
                    .clipped()
                HStack {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 64, height: 64)
                        
                    Text("Codelume is a dynamic wallpaper application designed exclusively for macOS, featuring a sleek design with comprehensive functionality. As a menu bar application, please remember to launch and use it from the menu bar—it won't be visible in your Dock.")
                        .font(.title3)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 10)
                }
                
                HStack {
                    Spacer()
                    Toggle("Show on next startup", isOn: $showAgain)
                        .font(.body)
                    Spacer()
                }
                
                Button("Get Started") {
                    UserDefaultsManager.shared.saveWelcomeStatus(showAgain)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Spacer()
            }
        }
        .frame(width: 550)
    }
}

#Preview {
    WelcomeView()
}
