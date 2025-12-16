import Foundation

extension Notification.Name {
    static let pause = Notification.Name("com.codelume.notification.pause")
    static let mute = Notification.Name("com.codelume.notification.mute")
    static let volume = Notification.Name("com.codelume.notification.volume")
    static let videoUrl = Notification.Name("com.codelume.notification.videoUrl")
    static let pauseIfOtherAppOnDesktop = Notification.Name("com.codelume.notification.pauseIfOtherAppOnDesktop")
    static let pauseIfOtherAppFullScreen = Notification.Name("com.codelume.notification.pauseIfOtherAppFullScreen")
    static let pauseIfBatteryPowered = Notification.Name("com.codelume.notification.pauseIfBatteryPowered")
    static let pauseIfPowerSaving = Notification.Name("com.codelume.notification.pauseIfPowerSaving")
    static let setWallpaperIsVisible = Notification.Name("com.codelume.notification.setWallpaperIsVisible")
    static let refreshVideoList = Notification.Name("com.codelume.notification.refreshVideoList")
    static let refreshPlayList = Notification.Name("com.codelume.notification.refreshPlayList")
    static let refreshLocalWallpaperList = Notification.Name("com.codelume.notification.refreshLocalWallpaperList")
    static let playConfigChanged = Notification.Name("com.codelume.notification.playConfigChanged")
    static let playItemChanged = Notification.Name("com.codelume.notification.playItemChanged")
    // 壁纸包改变通知
    static let wallpaperBundleChanged = Notification.Name("com.codelume.notification.wallpaperBundleChanged")
    static let screenPlayStateChanged = Notification.Name("com.codelume.notification.screenPlayStateChanged")
    // 屏幕配置改变通知
    static let screenConfigChanged = Notification.Name("com.codelume.notification.screenConfigChanged")
    // 全局播放状态改变通知
    static let playbackStateChanged = Notification.Name("com.codelume.notification.playStateChanged")
    // seek to zero
    static let seekToZero = Notification.Name("com.codelume.notification.seekToZero")

}
