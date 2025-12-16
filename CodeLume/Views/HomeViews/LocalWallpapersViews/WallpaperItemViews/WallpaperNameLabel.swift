import SwiftUI

struct WallpaperNameLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .foregroundColor(.black)
            .truncationMode(.middle)
            .lineLimit(1)
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(1.0))
            )
    }
}

#Preview {
    WallpaperNameLabel(text: "codelume_0.bundle")
        .frame(width: 300, height: 50)
}
