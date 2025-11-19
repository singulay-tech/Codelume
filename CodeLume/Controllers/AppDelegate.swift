import Cocoa
import SwiftUI
import SwiftyBeaver

// 由于PlaybackManager与AppDelegate在同一个模块中，不需要额外导入
class AppDelegate: NSObject, NSApplicationDelegate {
    let windowController = WindowController()
    private var welcomeWindow: NSWindow?
    
    // 应用启动时被调用
    func applicationWillFinishLaunching(_ notification: Notification) {
        // 确保开机自启默认关闭
        if UserDefaults.standard.object(forKey: "startAtLogin") == nil {
            UserDefaults.standard.set(false, forKey: "startAtLogin")
            UserDefaults.standard.synchronize()
            Logger.info("Set default startAtLogin to false")
        }
        
        // 启动播放管理器
        PlaybackManager.shared.start()
        Logger.info("CodeLume application started")
    }
    
    // 应用退出时被调用
    func applicationWillTerminate(_ notification: Notification) {
        // 停止播放管理器
        PlaybackManager.shared.stop()
        Logger.info("CodeLume application terminated")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查是否已经有应用实例在运行
        #if !DEBUG
        if isAppAlreadyRunning() {
            // 显示警告并退出当前实例
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("CodeLume is Running", comment: "")
            alert.informativeText = NSLocalizedString("The application is already running. Please access CodeLume through the top status bar.", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
            
            // 退出应用
            NSApp.terminate(nil)
            return
        }
        #endif
        let shouldShowWelcomeBySetting = UserDefaults.standard.object(forKey: "showWelcomeScreen") as? Bool ?? true
        
        
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
        
        // 创建窗口 - 使用无边框样式，移除所有控制按钮
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400), // 设置合理的初始大小
            styleMask: .borderless, // 使用无边框样式，移除关闭按钮和标题栏
            backing: .buffered,
            defer: false
        )
        
        // 配置窗口
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
