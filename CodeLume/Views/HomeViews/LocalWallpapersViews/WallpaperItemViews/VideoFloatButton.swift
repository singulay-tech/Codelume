import SwiftUI

struct VideoFloatButton: View {
    let text: LocalizedStringKey
    let color: Color
    let action: () -> Void
    
    init(text: LocalizedStringKey, color: Color = .black, action: @escaping () -> Void) {
        self.text = text
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundColor(color)
        }
        .truncationMode(.middle)
        .background(Color.white.opacity(1.0))
        .cornerRadius(8)
    }
}

#Preview {
    VideoFloatButton(text: "codelume", color: .black, action: {})
        .frame(width: 100, height: 50)
}
