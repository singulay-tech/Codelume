import AppKit
import SpriteKit

// SpriteKit播放视图
class SpriteKitPlaybackView: SKView {
    private var playScreen: NSScreen?
    private var screenConfiguration: ScreenConfiguration?
    
    init(frame: NSRect, config: ScreenConfiguration, screen: NSScreen) {
        super.init(frame: frame)
        screenConfiguration = config
        playScreen = screen
        setupScene()
        Logger.info("vis true \(self.screenConfiguration?.id)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Logger.info("Post visibility notification and start playback after delay for screen: \(self.screenConfiguration!.id)")
            NotificationCenter.default.post(name: .setWallpaperIsVisible,
                                            object: self.screenConfiguration?.id,
                                            userInfo: ["isVisible": true])
//            self.applyPlaybackSettings()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupScene() {
        let scene = SKScene(size: self.frame.size)
        scene.backgroundColor = .blue
        self.presentScene(scene)
        
        // 添加默认的SpriteKit内容
        let labelNode = SKLabelNode(text: "SpriteKit Demo")
        labelNode.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        labelNode.fontSize = 30
        labelNode.fontColor = .white
        scene.addChild(labelNode)
    }
}
