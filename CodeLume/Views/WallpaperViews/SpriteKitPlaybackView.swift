import AppKit
import SpriteKit

// SpriteKit播放视图
class SpriteKitPlaybackView: SKView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupScene() {
        let scene = SKScene(size: self.frame.size)
        scene.backgroundColor = .black
        self.presentScene(scene)
        
        // 添加默认的SpriteKit内容
        let labelNode = SKLabelNode(text: "SpriteKit Demo")
        labelNode.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        labelNode.fontSize = 30
        labelNode.fontColor = .white
        scene.addChild(labelNode)
    }
}
