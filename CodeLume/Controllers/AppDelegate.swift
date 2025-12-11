import Cocoa
import SwiftUI
import SwiftyBeaver

class AppDelegate: NSObject, NSApplicationDelegate {
    let windowController = WindowController()
    private var welcomeWindow: NSWindow?

    func applicationWillFinishLaunching(_ notification: Notification) {
        let _ = LogManager.shared
        let _ = UserDefaultsManager.shared

        PlaybackManager.shared.start()
        Logger.info("CodeLume application started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        PlaybackManager.shared.stop()
        Logger.info("CodeLume application terminated")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if !DEBUG
        if isAppAlreadyRunning() {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("CodeLume is Running", comment: "")
            alert.informativeText = NSLocalizedString("The application is already running. Please access CodeLume through the top status bar.", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()

            NSApp.terminate(nil)
            return
        }
        #endif

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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController
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
