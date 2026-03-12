import SwiftUI

struct DescriptionTextView: View {
    let desc: LocalizedStringKey
    var body: some View {
        Text(desc)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
    }
}

#Preview {
    DescriptionTextView(desc: "Codelume")
}
