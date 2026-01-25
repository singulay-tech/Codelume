import SwiftUI
import Foundation

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("Pause") private var pause: Bool = false
    @AppStorage("Mute") private var mute: Bool = false
    @AppStorage("Volume") private var volume: Double = 0.3
    
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
                NotificationCenter.default.post(name: .userDefaultChanged, object: nil)
            }
            
            Toggle(isOn: $mute) {
                Text("Mute")
            }
            .toggleStyle(.checkbox)
            .onChange(of: mute) { oldValue, newValue in
                mute = newValue
                NotificationCenter.default.post(name: .userDefaultChanged, object: nil)
            }
            
            Divider()
            
            Button("Import bundle") {
                importBundle()
            }
            
            Button("Import video") {
                importVideo()
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

