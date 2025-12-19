import SwiftUI

struct CloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.black, .red)
                .font(.system(size: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(15)
    }
}

#Preview {
    CloseButton(action: {})
        .frame(width: 50, height: 50)
}
