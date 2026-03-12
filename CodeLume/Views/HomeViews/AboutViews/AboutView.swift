import SwiftUI

struct AboutView: View {
    private let githubURL = URL(string: "https://github.com/singulay-tech/Codelume.git")!
    private let douyinURL = URL(string: "https://www.douyin.com/user/MS4wLjABAAAAl1srMN6bnoQL8gBUFGUa3wQZp7KJ4WHfXyfz16Us2syzqhhKKM-iDCW64v5enW9w?from_tab_name=main&vid=7573053246886006052")!
    private let emailAddress = "codelume@163.com"
    @State private var showingEmailSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .center, spacing: 8) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 4) {
                        Text("Codelume")
                            .font(.system(size: 28, weight: .bold))
                        Text("Version \(Bundle.main.appVersion)")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitleView(title: "About")
                    Text("Codelume is a native macOS dynamic wallpaper app designed for smooth playback, low resource usage, and a polished desktop experience.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.primary)
                    
                    Divider().padding(.vertical, 2)
                    
                    Text("Built with a privacy-first approach, Codelume runs inside the macOS sandbox and does not collect personal data. It is open source, transparent, and built for long-term reliability.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.secondary)
                }
                .aboutSectionCard()
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitleView(title: "Versions")
                    
                    IconTitleDescriptionView(
                        icon: "GithubIcon",
                        isSystemIcon: false,
                        title: "GitHub Open-Source Version",
                        description: "Supports custom builds and full code-level customization. This version does not connect to the server, so Wallpaper Hub content is unavailable."
                    )
                    
                    IconTitleDescriptionView(
                        icon: "apple.logo",
                        isSystemIcon: true,
                        title: "App Store Version",
                        description: "Integrated with Supabase services, offering both free and paid wallpapers with a richer and continuously expanding content ecosystem."
                    )
                    
                    Text("Due to limited testing resources, this app is only tested on the latest macOS systems. Older systems may experience compatibility issues. We recommend upgrading your system or compiling from source to resolve any issues.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                }
                .aboutSectionCard()
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitleView(title: "Wallpaper Content")
                    Text("Codelume is a platform dedicated to the playback engine; we do not produce wallpaper content ourselves. We recognize that the creator's work is paramount to the user experience. Therefore, we invite creators to submit their original wallpapers via email for potential inclusion. Creators have full control over the pricing of their work. Codelume will retain a small commission on each sale to support server maintenance and platform operations, with the remainder of the proceeds compensated directly to the creator. To ensure accessibility, a curated collection of free wallpapers will always be available on the platform.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Submission Requirements:")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Format: .mp4 or .mov")
                        Text("• Max size: 50 MB")
                        Text("• Min resolution: 1080P (4K recommended)")
                        Text("• Must support seamless looping")
                    }
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Note: Paid features are currently in development. All wallpapers are available for free at this time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 4)
                    
                    Text("Some materials are sourced from the internet. If any content infringes on your rights, please contact us using the contact methods at the bottom of this page.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 4)
                }
                .aboutSectionCard()
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitleView(title: "Contact & Support")
                    
                    IconTitleDescriptionView(
                        icon: "envelope",
                        isSystemIcon: true,
                        title: "Email",
                        description: "Submit wallpapers or report copyright issues."
                    )
                    
                    IconTitleDescriptionView(
                        icon: "douyinIcon",
                        isSystemIcon: false,
                        title: "Douyin",
                        description: "New wallpapers, version updates, and technical insights."
                    )
                    
                    IconTitleDescriptionView(
                        icon: "GithubIcon",
                        isSystemIcon: false,
                        title: "GitHub",
                        description: "Report issues, request features, or contribute code."
                    )
                    
                    Text("All contact methods are listed at the bottom of this page.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                }
                .aboutSectionCard()
                
                VStack(spacing: 16) {
                    Divider()
                    
                    HStack(spacing: 20) {
                        SocialButtonView(
                            url: douyinURL,
                            iconName: "douyinIcon",
                            fallbackIcon: "video",
                            label: "Douyin"
                        )
                        
                        SocialButtonView(
                            url: githubURL,
                            iconName: "GithubIcon",
                            fallbackIcon: "curlybraces",
                            label: "GitHub"
                        )
                        
                        Button(action: { showingEmailSheet = true }) {
                            Label {
                                Text("Email")
                                    .font(.callout)
                            } icon: {
                                Image(systemName: "envelope")
                                    .font(.system(size: 14))
                                    .imageScale(.large)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("Made with ♥ for the macOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                .padding(.horizontal, 8)
            }
            .padding()
        }
        .sheet(isPresented: $showingEmailSheet) {
            EmailContactView(emailAddress: emailAddress)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    AboutView()
}
