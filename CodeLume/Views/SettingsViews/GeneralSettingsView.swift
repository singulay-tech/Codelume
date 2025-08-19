import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    enum Language: String, CaseIterable {
        case system = "Follow system"
        case chinese = "Chinese"
        case english = "English"
    }
    enum Theme: String, CaseIterable {
        case system = "Follow system"
        case light = "Light"
        case dark = "Dark"
    }
    
    @AppStorage("selectedLanguage") private var selectedLanguage: String = Language.system.rawValue
    @AppStorage("selectedTheme") private var selectedTheme: String = Theme.system.rawValue
    @AppStorage("startAtLogin") private var startAtLogin: Bool = false {
        didSet {
            setStartAtLogin(startAtLogin)
        }
    }
    
    @State private var lastHideDockIconToggleTime: Date = .distantPast
    @State private var showRestartAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Language settings:", systemImage: "translate")
                Spacer()
                MenuButton(label: Text(LocalizedStringKey(selectedLanguage))) {
                    ForEach(Language.allCases, id: \.self) { language in
                        Button(action: {
                            selectedLanguage = language.rawValue
                            setAppLanguage(language)
                        }) {
                            Text(LocalizedStringKey(language.rawValue))
                        }
                    }
                }
                .frame(width: 130)
            }
            Divider()
            HStack {
                Label("Theme settings:", systemImage: "paintpalette")
                Spacer()
                MenuButton(label: Text(LocalizedStringKey(selectedTheme))) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Button(action: {
                            selectedTheme = theme.rawValue
                            setAppTheme(theme)
                        }) {
                            Text(LocalizedStringKey(theme.rawValue))
                        }
                    }
                }
                .frame(width: 130)
            }
            Divider()
            
            IconToggle(iconName: "power.circle", title: "Start at login", isOn: $startAtLogin) {
                newValue in
                startAtLogin = newValue
            }
            Spacer()
        }
        .padding()
        .onAppear {
            startAtLogin = isStartAtLoginEnabled()
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Restart Now", role: .destructive) {
                restartApplication()
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Please restart the app to apply the new language settings.")
        }
    }
    
    private func setAppLanguage(_ language: Language) {
        let currentLanguage = UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String ?? ""
        var newLanguage: String
        switch language {
        case .system:
            newLanguage = ""
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .chinese:
            newLanguage = "zh-Hans-CN"
            UserDefaults.standard.set(["zh-Hans-CN"], forKey: "AppleLanguages")
        case .english:
            newLanguage = "en"
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        Logger.info("new language: \(newLanguage), current language: \(currentLanguage)")
        if currentLanguage != newLanguage {
            showRestartAlert = true
        }
    }
    
    private func setAppTheme(_ theme: Theme) {
        switch theme {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleInterfaceStyle")
            NSApp.appearance = nil
        case .light:
            UserDefaults.standard.set("Light", forKey: "AppleInterfaceStyle")
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            UserDefaults.standard.set("Dark", forKey: "AppleInterfaceStyle")
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        UserDefaults.standard.synchronize()
        Logger.info("new theme: \(theme.rawValue)")
        NSApplication.shared.windows.forEach { window in
            window.appearance = NSApp.appearance
        }
    }
    
    private func setStartAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            Logger.info("Start at login set to \(enabled)")
        } catch {
            Logger.error("Failed to set start at login to \(enabled): \(error.localizedDescription)")
        }
    }
    
    private func isStartAtLoginEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}

#Preview {
    GeneralSettingsView()
}
