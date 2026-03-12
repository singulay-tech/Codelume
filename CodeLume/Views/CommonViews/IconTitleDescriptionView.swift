import SwiftUI

struct IconTitleDescriptionView: View {
    let icon: String
    let isSystemIcon: Bool
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    var email: String? = nil
    var buttonTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if isSystemIcon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 18, height: 18)
                    .padding(.leading, 12)
            } else {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 18, height: 18)
                    .padding(.leading, 12)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let email = email {
                    Text(email)
                        .font(.callout.monospaced())
                        .foregroundColor(.accentColor)
                        .textSelection(.enabled)
                        .padding(.top, 2)
                }
                
                if let buttonTitle = buttonTitle, let action = action {
                    Button(action: action) {
                        Text(buttonTitle)
                            .font(.callout)
                    }
                    .buttonStyle(.link)
                    .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    IconTitleDescriptionView(
        icon: "GithubIcon",
        isSystemIcon: false,
        title: "GitHub",
        description: "github."
    )
}
