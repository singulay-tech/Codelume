import SwiftUI

struct SocialButtonView: View {
    let url: URL
    let iconName: String
    let fallbackIcon: String
    let label: LocalizedStringKey
    
    var body: some View {
        Button(action: { NSWorkspace.shared.open(url) }) {
            HStack(spacing: 6) {
                if NSImage(named: iconName) != nil {
                    Image(nsImage: NSImage(named: iconName)!)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: fallbackIcon)
                        .font(.system(size: 18))
                }
                
                Text(label)
                    .font(.callout)
            }
            .frame(width: 80)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    let githubURL = URL(string: "https://github.com/singulay-tech/Codelume.git")!
    SocialButtonView(url: githubURL, iconName: "GithubIcon", fallbackIcon: "curlybraces", label: "GitHub")
}
