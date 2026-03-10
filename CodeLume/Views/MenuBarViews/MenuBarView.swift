//
//  UserAuthView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import SwiftUI
import Foundation

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage(PAUSE) private var pause: Bool = UserDefaultsManager.shared.getPauseStatus()
    @AppStorage(MUTE) private var mute: Bool = UserDefaultsManager.shared.getMuteStatus()
    @AppStorage(VOLUME) private var volume: Double = Double(UserDefaultsManager.shared.getVolume())
    
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
            
            Button("Import Wallpapers") {
                importWallpapers()
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

