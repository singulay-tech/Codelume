import SwiftUI

struct CodelumeIcon: View {
    var body: some View {
        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
            .resizable()
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .primary.opacity(0.1), radius: 4, y: 2)
            .padding(.top, 16)
    }
}

#Preview {
    CodelumeIcon()
}
