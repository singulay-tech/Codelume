import SwiftUI

struct AboutView: View {
    private let githubURL = URL(string: "https://github.com/guang-zi-yu/CodelumeApp.git")!
    private let douyinURL = URL(string: "https://www.douyin.com/user/MS4wLjABAAAAl1srMN6bnoQL8gBUFGUa3wQZp7KJ4WHfXyfz16Us2syzqhhKKM-iDCW64v5enW9w?from_tab_name=main&vid=7573053246886006052")!
    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/%E7%A0%81%E9%95%9C/id6751061329?mt=12")!
    private let emailAddress = "codelume@163.com"
    @State private var showingEmailSheet = false
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                    Text("Codelume is a native, open-source dynamic wallpaper application built exclusively for macOS.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.primary)
                    
                    Divider().padding(.vertical, 2)
                    
                    Text("The app runs strictly within the macOS sandbox, requires no network permissions, and never collects user data.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitleView(title: "Get Codelume")
                    
                    OptionView(
                        icon: "GithubIcon",
                        isSystemIcon: false,
                        title: "Open Source Version",
                        description: "Completely free. Clone, build, and customize from GitHub.",
                        buttonTitle: "View on GitHub",
                        action: { NSWorkspace.shared.open(githubURL) }
                    )
                    
                    OptionView(
                        icon: "apple.logo",
                        isSystemIcon: true,
                        title: "App Store Version",
                        description: "Paid download to support Apple Developer Program costs. Auto-updated.",
                        buttonTitle: "View on App Store",
                        action: { NSWorkspace.shared.open(appStoreURL) }
                    )
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitleView(title: "Wallpaper Content")
                    Text("We focus solely on the playback engine. For video wallpapers, we recommend using compatible content from platforms like **Wallpaper Engine**. We welcome collaboration with original creators.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitleView(title: "Contact & Support")
                    
                    OptionView(
                        icon: "envelope",
                        isSystemIcon: true,
                        title: "Email Support",
                        description: "For technical support, collaboration inquiries, or feedback.",
                        email: emailAddress
                    ) {
                        showingEmailSheet = true
                    }
                    
                    OptionView(
                        icon: "DouyinIcon",
                        isSystemIcon: false,
                        title: "Douyin",
                        description: "Follow us for updates, demos, and community content.",
                        buttonTitle: "Visit Codelume's Douyin",
                        action: { NSWorkspace.shared.open(douyinURL) }
                    )
                }
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Divider()
                    
                    HStack(spacing: 20) {
                        SocialButtonView(
                            url: douyinURL,
                            iconName: "DouyinIcon",
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
                .padding(.top, 8)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingEmailSheet) {
            EmailContactView(emailAddress: emailAddress)
        }
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

extension Bundle {
    var appVersion: String {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

#Preview {
    AboutView()
}
