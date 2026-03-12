import SwiftUI

struct SectionTitleView: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 2)
    }
}

#Preview {
    SectionTitleView(title: "Codelume")
}
