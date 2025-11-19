import SwiftUI

@main
struct CodeLumeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        MenuBarExtra("CodeLume", image: "CodeLumeIcon") {
            MenuBarView()
                .onAppear {
                    let theme = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
                    switch theme {
                    case "Light":
                        NSApp.appearance = NSAppearance(named: .aqua)
                    case "Dark":
                        NSApp.appearance = NSAppearance(named: .darkAqua)
                    default:
                        NSApp.appearance = nil
                    }
                }
        }
        
        WindowGroup("CodeLume", id: "home") {
            HomeView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 600)
        .windowResizability(.contentSize)
    }
}
