import SwiftUI
import Foundation


struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @AppStorage("pause") private var pause: Bool = false {
        didSet {
           NotificationCenter.default.post(name: .pause, object: pause)
        }
    }
    @AppStorage("mute") private var mute: Bool = false {
        didSet {
           NotificationCenter.default.post(name: .mute, object: mute)
        }
    }
    
    var body: some View {
        VStack {
            Divider()
            Button("Home") {
                openOrBringToFrontWindow(id: "home")
            }
           Divider()
           Toggle(isOn: $pause) {
               Text("Pause")
           }
           .toggleStyle(.checkbox)
           .onChange(of: pause) { oldValue, newValue in
               pause = newValue
           }
            Divider()
            Button("Import external wallpaper") {
                importExternalWallpaper()
            }
            Divider()
            Button("Rstart") {
                restartApplication()
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        
    }
    
    func openOrBringToFrontWindow(id: String) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.hasPrefix(id) == true }) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        } else {
            openWindow(id: id)
        }
    }
}

