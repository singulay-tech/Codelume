import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let windowController = WindowController()
    private var welcomeWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查是否已经有应用实例在运行
        if isAppAlreadyRunning() {
            // 显示警告并退出当前实例
            let alert = NSAlert()
            alert.messageText = "CodeLume is Running"
            alert.informativeText = "The application is already running. Please access CodeLume through the top status bar."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            // 退出应用
            NSApp.terminate(nil)
            return
        }
        let shouldShowWelcomeBySetting = UserDefaults.standard.bool(forKey: "showWelcomeScreen") // 默认值为true
        
        if shouldShowWelcomeBySetting {
            // 延迟显示欢迎界面，确保应用完全加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showWelcomeWindow()
            }
        }
    }
    
    private func showWelcomeWindow() {
        // 创建SwiftUI视图的NSHostingController
        let welcomeView = WelcomeView()
        let hostingController = NSHostingController(rootView: welcomeView)
        
        // 创建窗口 - 使用borderless样式掩码并启用圆角
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )
        
        // 配置窗口
        window.title = "Welcome to CodeLume"
        window.contentViewController = hostingController
        
        
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // 保存窗口引用
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
