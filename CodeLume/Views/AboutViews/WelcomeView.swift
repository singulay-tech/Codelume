import SwiftUI

struct WelcomeView: View {
    @State private var showAgain = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
            
            Text("Welcome to CodeLume! To control the installation package size, we have built-in default dynamic wallpapers that have been automatically loaded. For more operations, please find the C-shaped icon in the status bar and click on it.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
            
            Text("This software is free to use. In addition to the built-in wallpapers, this installation package does not include other wallpapers. In the future, there will be dedicated servers to support each user in creating their own wallpapers and sharing them. Developers are working hard to improve the software. If you encounter any issues or have suggestions during use, please contact us through the About interface.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
            
            HStack {
                Spacer()
                Toggle("Show on next startup", isOn: $showAgain)
                    .font(.body)
                Spacer()
            }
            .padding(.horizontal, 40)
            
            Button("Get Started") {
                UserDefaults.standard.set(showAgain, forKey: "showWelcomeScreen")
                UserDefaults.standard.synchronize()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 20)
        }
        .padding(40)
        .frame(minWidth: 550, minHeight: 450)
    }
}

#Preview {
    WelcomeView()
}
