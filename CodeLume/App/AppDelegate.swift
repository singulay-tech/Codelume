import Cocoa
import SwiftUI
import SwiftyBeaver

class AppDelegate: NSObject, NSApplicationDelegate {
    let windowController = WindowController()
    private var welcomeWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        let _ = SwiftyBeaverLog.shared
        let _ = UserDefaultsManager.shared
        let _ = DatabaseManger.shared
        let _ = ScreenManager.shared
        Logger.info("Codelume application started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.info("Codelume application terminated")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let theme = UserDefaultsManager.shared.getTheme()
        switch theme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
        
//        if isAppAlreadyRunning() {
//            let alert = NSAlert()
//            alert.messageText = NSLocalizedString("Codelume is Running", comment: "")
//            alert.informativeText = NSLocalizedString("The application is already running. Please access Codelume through the top status bar.", comment: "")
//            alert.alertStyle = .warning
//            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
//            alert.runModal()
//            
//            NSApp.terminate(nil)
//            return
//        }
        
        let showWelcomeView = UserDefaultsManager.shared.getWelcomeStatus()
        if showWelcomeView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showWelcomeWindow()
            }
        }
    }
    
    private func showWelcomeWindow() {
        let welcomeView = WelcomeView()
        let hostingController = NSHostingController(rootView: welcomeView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 300),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.isOpaque = false
        window.backgroundColor = .clear
        
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 20.0
            contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        welcomeWindow = window
    }
    
    private func isAppAlreadyRunning() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier!
        let runningApps = NSWorkspace.shared.runningApplications
        
        let otherInstances = runningApps.filter {
            $0.bundleIdentifier == bundleID
            && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }
        
        return !otherInstances.isEmpty
    }
}
