import Foundation

extension Notification.Name {
    static let setWallpaperIsVisible = Notification.Name("com.codelume.notification.setWallpaperIsVisible") // 设置壁纸可见性
    static let screenConfigChanged = Notification.Name("com.codelume.notification.screenConfigChanged") // 屏幕配置改变通知
    // static let refreshVideoList = Notification.Name("com.codelume.notification.refreshVideoList")
    // static let refreshPlayList = Notification.Name("com.codelume.notification.refreshPlayList")
    static let refreshLocalWallpaperList = Notification.Name("com.codelume.notification.refreshLocalWallpaperList")
    static let userDefaultChanged = Notification.Name("com.codelume.notification.userDefaultChanged")
    // static let playItemChanged = Notification.Name("com.codelume.notification.playItemChanged")
    // // 壁纸包改变通知
    static let wallpaperBundleChanged = Notification.Name("com.codelume.notification.wallpaperBundleChanged")
    static let screenTemporaryStateChanged = Notification.Name("com.codelume.notification.screenTemporaryStateChanged") // 临时状态的改变
    static let refreshScreenManagerView = Notification.Name("com.codelume.notification.refreshScreenManagerView")
}
