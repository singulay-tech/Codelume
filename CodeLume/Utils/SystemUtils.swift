//
//  SystemUtils.swift
//  CodeLume
//
//  Created by Lyke on 2025/3/20.
//

import AppKit
import Foundation
import IOKit.ps

func restartApplication() {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "sleep 1 && open \"\(Bundle.main.bundlePath)\""]
    task.launch()
    NSApplication.shared.terminate(nil)
}

func setDockIconVisibility(_ hide: Bool) {
    let policy: NSApplication.ActivationPolicy = hide ? .accessory : .regular
    let success = NSApp.setActivationPolicy(policy)
    
    if success {
        Logger.info("Dock icon visibility set to \(hide ? "hidden" : "visible") successfully.")
    } else {
        Logger.warning("Failed to set dock icon visibility to \(hide ? "hidden" : "visible").")
    }
}

func isOtherAppOnDesktop() -> Bool {
    Logger.debug("Checking if other apps are on desktop.")
    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else {
        Logger.warning("Failed to get window list.")
        return false
    }
    
    for window in windowList {
        guard let windowLayer = window[kCGWindowLayer as String] as? Int,
              windowLayer == CGWindowLevelForKey(.normalWindow)
        else {
            continue
        }
        
        if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
           let width = bounds["Width"], let height = bounds["Height"], width > 0 && height > 0
        {
            Logger.debug("Found other app on desktop.")
            return true
        }
    }
    Logger.debug("No other apps found on desktop.")
    return false
}

func isAppFullScreen() -> Bool {
    Logger.debug("Checking if app is in full screen mode.")
    guard let activeApp = NSWorkspace.shared.frontmostApplication else {
        Logger.warning("Failed to get frontmost application.")
        return false
    }
    
    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else {
        Logger.warning("Failed to get window list.")
        return false
    }
    
    for window in windowList {
        guard let ownerName = window[kCGWindowOwnerName as String] as? String,
              ownerName == activeApp.localizedName,
              let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
              let width = bounds["Width"],
              let height = bounds["Height"]
        else {
            continue
        }
        
        let screen = NSScreen.main!
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        
        if width == screenWidth && height == screenHeight {
            if let windowLayer = window[kCGWindowLayer as String] as? Int,
               windowLayer == CGWindowLevelForKey(.normalWindow)
            {
                Logger.debug("App is in full screen mode.")
                return true
            }
        }
    }
    Logger.debug("App is not in full screen mode.")
    return false
}

func isBatteryPowered() -> Bool {
    Logger.debug("Checking if device is on battery power.")
    let powerSource = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    if let powerSourceList = IOPSCopyPowerSourcesList(powerSource).takeRetainedValue() as NSArray?
        as? [AnyObject],
       let powerSourceInfo = IOPSGetPowerSourceDescription(powerSource, powerSourceList[0])
        .takeUnretainedValue() as? [String: AnyObject]
    {
        let isBattery =
        powerSourceInfo[kIOPSPowerSourceStateKey] as? String == kIOPSBatteryPowerValue
        Logger.debug("Device is \(isBattery ? "" : "not ")on battery power.")
        return isBattery
    }
    Logger.warning("Failed to get power source info.")
    return false
}

func isPowerSavingMode() -> Bool {
    Logger.debug("Checking if device is in power saving mode.")
    let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    Logger.debug("Device is \(isLowPower ? "" : "not ")in power saving mode.")
    return isLowPower
}
