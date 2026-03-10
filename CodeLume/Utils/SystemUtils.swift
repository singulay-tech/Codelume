//
//  SystemUtils.swift
//  Codelume
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

func isOtherAppOnScreen(_ screen: NSScreen) -> Bool {
    Logger.debug("Checking if other apps are on screen: \(screen.identifier)")
    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else {
        Logger.warning("Failed to get window list.")
        return false
    }
    
    let screenFrame = screen.frame
    Logger.debug("Screen frame: origin=(\(screenFrame.origin.x), \(screenFrame.origin.y)), size=(\(screenFrame.size.width), \(screenFrame.size.height))")
    
    // 获取主屏幕，用于坐标系转换参考
    let mainScreen = NSScreen.main
    let mainScreenHeight = mainScreen?.frame.height ?? 0
    
    for window in windowList {
        // 获取窗口所有者信息
        let windowOwnerName = window[kCGWindowOwnerName as String] as? String ?? "Unknown"
        let windowOwnerPID = window[kCGWindowOwnerPID as String] as? Int ?? -1
        let windowNumber = window[kCGWindowNumber as String] as? Int ?? -1
        
        // 排除自身应用的窗口
        if let windowOwnerPID = window[kCGWindowOwnerPID as String] as? Int {
            if windowOwnerPID == getpid() {
                continue
            }
        }
        
        // 检查窗口层级，放宽限制以捕获更多可能的窗口类型
        if let windowLayer = window[kCGWindowLayer as String] as? Int {
            // 允许普通窗口、桌面窗口和模态面板窗口
            let normalWindowLevel = CGWindowLevelForKey(.normalWindow)
            let desktopWindowLevel = CGWindowLevelForKey(.desktopWindow)
            let modalPanelWindowLevel = CGWindowLevelForKey(.modalPanelWindow)
            
            let allowedLayers = [normalWindowLevel, desktopWindowLevel, modalPanelWindowLevel]
            let windowCGLevel = CGWindowLevel(windowLayer)
            
            if !allowedLayers.contains(windowCGLevel) {
                // 记录被排除的窗口层级信息，以便调试
                Logger.debug("Skipping window \(windowOwnerName) with level \(windowCGLevel) not in allowed layers \(allowedLayers)")
                continue
            }
        }
        
        if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
           let x = bounds["X"], let y = bounds["Y"],
           let width = bounds["Width"], let height = bounds["Height"], width > 0 && height > 0
        {
            // CGWindow使用的坐标系可能与NSScreen不同，需要进行转换
            // 转换窗口坐标系到NSScreen坐标系（处理坐标系Y轴反转问题）
            let flippedY = mainScreenHeight > 0 ? mainScreenHeight - y - height : y
            let windowFrame = CGRect(x: x, y: flippedY, width: width, height: height)
            Logger.debug("Window: \(windowOwnerName) (PID: \(windowOwnerPID), #\(windowNumber)), frame: origin=(\(x), \(y)), size=(\(width), \(height)), flippedY=\(flippedY)")
            
            // 使用两种方法检测窗口是否在屏幕上：
            // 1. 检查窗口框架是否与屏幕框架有交集
            let intersection = windowFrame.intersection(screenFrame)
            
            // 2. 检查窗口中心点是否在屏幕内（作为备用检测方法）
            let windowCenter = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
            let isCenterInScreen = screenFrame.contains(windowCenter)
            
            // 如果交集区域不为空或者窗口中心点在屏幕内，则认为窗口在屏幕上
            if !intersection.isEmpty || isCenterInScreen {
                Logger.debug("Found other app on screen: \(screen.identifier) - App: \(windowOwnerName) (Intersection area: \(intersection.width * intersection.height), Center in screen: \(isCenterInScreen))")
                return true
            } else {
                Logger.debug("Window \(windowOwnerName) does not intersect with screen \(screen.identifier)")
                Logger.debug("  Window center: (\(windowCenter.x), \(windowCenter.y)), Screen contains center: \(isCenterInScreen)")
            }
        }
    }
    Logger.debug("No other apps found on screen: \(screen.identifier)")
    return false
}

// 保留原函数以便向后兼容
func isOtherAppOnDesktop() -> Bool {
    // 默认检查主屏幕
    guard let mainScreen = NSScreen.main else {
        Logger.warning("Main screen not found.")
        return false
    }
    return isOtherAppOnScreen(mainScreen)
}

func isAnyAppFullScreenOnScreen(_ screen: NSScreen) -> Bool {
    Logger.debug("Checking if any app is in full screen mode on screen: \(screen.identifier)")
    
    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else {
        Logger.warning("Failed to get window list.")
        return false
    }
    
    let screenFrame = screen.frame
    let screenWidth = screenFrame.width
    let screenHeight = screenFrame.height
    
    // 考虑刘海屏和菜单栏，允许一定的容差百分比
    let coverageThreshold: CGFloat = 0.90
    
    for window in windowList {
        guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
              let x = bounds["X"], let y = bounds["Y"],
              let width = bounds["Width"], let height = bounds["Height"], width > 0 && height > 0
        else {
            continue
        }
        
        let windowFrame = CGRect(x: x, y: y, width: width, height: height)
        
        Logger.debug("Window dimensions: \(width)x\(height) at (\(x), \(y))")
        Logger.debug("Screen dimensions: \(screenWidth)x\(screenHeight)")
        
        // 使用两种方法检测窗口是否在屏幕上：
        // 1. 检查窗口框架是否与屏幕框架有交集
        let intersection = windowFrame.intersection(screenFrame)
        
        // 2. 检查窗口中心点是否在屏幕内（作为备用检测方法）
        let windowCenter = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        let isCenterInScreen = screenFrame.contains(windowCenter)
        
        // 只有窗口中心在该屏幕内，且覆盖该屏幕大部分区域时才认为是该屏幕全屏
        if isCenterInScreen, !intersection.isEmpty {
            let intersectionArea = intersection.width * intersection.height
            let screenArea = screenWidth * screenHeight
            let coverage = screenArea > 0 ? intersectionArea / screenArea : 0

            Logger.debug("Intersection area: \(intersectionArea), Screen area: \(screenArea), coverage: \(coverage)")

            if let windowLayer = window[kCGWindowLayer as String] as? Int,
               windowLayer == CGWindowLevelForKey(.normalWindow),
               coverage >= coverageThreshold {
                
                if let ownerName = window[kCGWindowOwnerName as String] as? String {
                    Logger.debug("App \(ownerName) is in full screen mode on screen: \(screen.identifier)")
                } else {
                    Logger.debug("An app is in full screen mode on screen: \(screen.identifier)")
                }
                return true
            }
        } else {
            Logger.debug("Window does not intersect with screen \(screen.identifier)")
            Logger.debug("  Window center: (\(windowCenter.x), \(windowCenter.y)), Screen contains center: \(isCenterInScreen)")
        }
    }
    Logger.debug("No apps in full screen mode on screen: \(screen.identifier)")
    return false
}

// 保留原函数以便向后兼容
func isAppFullScreen() -> Bool {
    Logger.debug("Checking if frontmost app is in full screen mode.")
    guard let activeApp = NSWorkspace.shared.frontmostApplication else {
        Logger.warning("Failed to get frontmost application.")
        return false
    }
    
    guard let mainScreen = NSScreen.main else {
        Logger.warning("Main screen not found.")
        return false
    }
    
    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else {
        Logger.warning("Failed to get window list.")
        return false
    }
    
    let screenWidth = mainScreen.frame.width
    let screenHeight = mainScreen.frame.height
    
    for window in windowList {
        guard let ownerName = window[kCGWindowOwnerName as String] as? String,
              ownerName == activeApp.localizedName,
              let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
              let width = bounds["Width"], let height = bounds["Height"],
              width == screenWidth && height == screenHeight
        else {
            continue
        }
        
        if let windowLayer = window[kCGWindowLayer as String] as? Int,
           windowLayer == CGWindowLevelForKey(.normalWindow)
        {
            Logger.debug("Frontmost app \(activeApp.localizedName) is in full screen mode.")
            return true
        }
    }
    Logger.debug("Frontmost app is not in full screen mode.")
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
