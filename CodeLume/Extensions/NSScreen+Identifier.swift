import AppKit

// MARK: - 扩展NSScreen
extension NSScreen {
    var deviceID: String {
        return self.localizedName
    }
    
    var identifier: String {
        return self.localizedName
    }
    
    var isMain: Bool {
        return self == NSScreen.main
    }
    
    var physicalSizeInches: String {
        let screenFrame = self.frame
        let widthPixels = screenFrame.width
        let heightPixels = screenFrame.height
        
        // 获取屏幕密度
        let backingScaleFactor = self.backingScaleFactor
        
        // 计算物理尺寸（假设ppi为220，实际应根据设备查询）
        let widthInches = widthPixels / backingScaleFactor / 220.0
        let heightInches = heightPixels / backingScaleFactor / 220.0
        
        // 计算对角线尺寸
        let diagonalInches = sqrt(widthInches * widthInches + heightInches * heightInches)
        
        return String(format: "%.1f\"", diagonalInches)
    }
    
    // 获取屏幕密度
    var density: String {
        let backingScaleFactor = self.backingScaleFactor
        return String(format: "%.1fx", backingScaleFactor)
    }
}
