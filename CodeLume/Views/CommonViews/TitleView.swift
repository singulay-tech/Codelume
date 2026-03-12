import SwiftUI

struct TitleView: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title)
            .font(.title)
            .fontWeight(.bold)
            .padding(.bottom, 10)
    }
}

#Preview {
    TitleView(title: "Codelume")
}
