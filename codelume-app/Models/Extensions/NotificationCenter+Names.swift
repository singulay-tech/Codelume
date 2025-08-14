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
    static let playVideoUrlChanged = Notification.Name("com.codelume.notification.playVideoUrlChanged")
}
