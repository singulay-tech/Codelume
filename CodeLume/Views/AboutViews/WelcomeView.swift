import SwiftUI

struct WelcomeView: View {
    @State private var showAgain = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Image("Welcome_1")
                .resizable()
                .scaledToFit()
            HStack {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 64, height: 64)
                Text("Congratulations on discovering this free treasure of an app! CodeLume is a dynamic wallpaper application designed exclusively for macOS, boasting a sleek and elegant design with comprehensive functionality. As a menu bar application, please remember to launch and use it from the menu bar—it won't be visible in your Dock.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
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
                UserDefaults.standard.set(showAgain, forKey: "showWelcomeScreen")
                UserDefaults.standard.synchronize()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .frame(minWidth: 650, minHeight: 440)
    }
}

#Preview {
    WelcomeView()
}
