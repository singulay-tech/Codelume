import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @State private var selectedLanguage: String = UserDefaultsManager.shared.getLanguage().rawValue
    @State private var selectedTheme: String = UserDefaultsManager.shared.getTheme().rawValue
    @State private var showWelcomeView: Bool = UserDefaultsManager.shared.getWelcomeStatus()
    @State private var startAtLogin: Bool = UserDefaultsManager.shared.getStartAtLogin()
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
            HStack {
                Label("Show welcome screen at startup", systemImage: "star.fill")
                Spacer()
                Toggle("", isOn: $showWelcomeView)
                    .toggleStyle(.switch)
                    .frame(width: 50)
                    .padding(.trailing, 20)
                    .onChange(of: showWelcomeView) { oldValue, newValue in
                        UserDefaultsManager.shared.saveWelcomeStatus(newValue)
                    }
            }
            
            HStack {
                Label("Start at login", systemImage: "power.circle")
                Spacer()
                Toggle("", isOn: $startAtLogin)
                    .toggleStyle(.switch)
                    .frame(width: 50)
                    .padding(.trailing, 20)
                    .onChange(of: startAtLogin) { oldValue, newValue in
                        setStartAtLogin(newValue)
                    }
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
        let currentLanguage = UserDefaultsManager.shared.getLanguage().rawValue
        Logger.info("new language: \(language.rawValue), current language: \(currentLanguage)")
        UserDefaultsManager.shared.saveLanguage(language)
        if currentLanguage != language.rawValue {
            showRestartAlert = true
        }
    }
    
    private func setAppTheme(_ theme: Theme) {
        Logger.info("Set theme to \(theme.rawValue)")
        switch theme {
        case .system:
            UserDefaultsManager.shared.clearThemeConfig()
            NSApp.appearance = nil
        case .light:
            UserDefaultsManager.shared.saveTheme(.light)
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            UserDefaultsManager.shared.saveTheme(.dark)
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
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
