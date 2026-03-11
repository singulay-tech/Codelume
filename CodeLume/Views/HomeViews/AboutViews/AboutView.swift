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
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .primary.opacity(0.1), radius: 4, y: 2)
                    
                    VStack(spacing: 6) {
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
                    
                    OptionView(
                        icon: "GithubIcon",
                        isSystemIcon: false,
                        title: "GitHub Open-Source Version",
                        description: "Supports custom builds and full code-level customization. This version does not connect to the server, so Wallpaper Hub content is unavailable."
                    )
                    
                    OptionView(
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
                    Text("Codelume focuses on the playback engine—we don't create wallpaper content. Wallpaper quality determines the ceiling of the entire experience. If you have original wallpapers, you can submit them via email for other users to purchase. Pricing is decided by the original creator. Codelume takes a small share to cover server maintenance and development; the rest goes to the creator. Of course, there will always be free wallpapers available.")
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
                    
                    OptionView(
                        icon: "envelope",
                        isSystemIcon: true,
                        title: "Email",
                        description: "Submit wallpapers or report copyright issues."
                    )
                    
                    OptionView(
                        icon: "douyinIcon",
                        isSystemIcon: false,
                        title: "Douyin",
                        description: "New wallpapers, version updates, and technical insights."
                    )
                    
                    OptionView(
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
                            Label("Email", systemImage: "envelope")
                                .font(.callout)
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
            .padding(.horizontal, 24)
            .padding(.top, 0)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showingEmailSheet) {
            EmailContactView(emailAddress: emailAddress)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

struct EmailContactView: View {
    let emailAddress: String
    @Environment(\.dismiss) private var dismiss
    @State private var emailSubject = ""
    @State private var emailBody = ""
    @State private var isShowingMailDialog = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Support Email", systemImage: "envelope")
                            .font(.headline)
                        Text(emailAddress)
                            .textSelection(.enabled)
                            .foregroundColor(.accentColor)
                            .font(.body.monospaced())
                        
                        Button("Copy Email Address") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(emailAddress, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Contact Information")
                }
                
                Section {
                    TextField("Subject", text: $emailSubject)
                        .textFieldStyle(.roundedBorder)
                    
                    TextEditor(text: $emailBody)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    HStack {
                        Text("Your message will open in your default email client.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        
                        Button("Open in Mail") {
                            openEmailClient()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(emailSubject.isEmpty && emailBody.isEmpty)
                    }
                    .padding(.top, 8)
                } header: {
                    Text("Compose Message")
                } footer: {
                    Text("We typically respond within 1-2 business days.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .frame(width: 500, height: 450)
            .navigationTitle("Contact via Email")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openEmailClient() {
        let subject = emailSubject.isEmpty ? "Codelume Inquiry" : emailSubject
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoURLString = "mailto:\(emailAddress)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURLString) {
            NSWorkspace.shared.open(url)
            dismiss()
        }
    }
}

struct OptionView: View {
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
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: fallbackIcon)
                        .font(.system(size: 16))
                }
                
                Text(label)
                    .font(.callout)
            }
            .frame(minWidth: 80)
        }
        .buttonStyle(.bordered)
    }
}

struct SectionTitleView: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 2)
    }
}

private extension View {
    func aboutSectionCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
    }
}

extension Bundle {
    var appVersion: String {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

#Preview {
    AboutView()
}
