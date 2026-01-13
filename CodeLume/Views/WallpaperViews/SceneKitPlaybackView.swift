import AppKit
import SceneKit

// SceneKit播放视图
class SceneKitPlaybackView: SCNView {
    private var playScreen: NSScreen?
    private var screenConfiguration: ScreenConfiguration?
    
    init(frame: NSRect, config: ScreenConfiguration, screen: NSScreen) {
        super.init(frame: frame)
        screenConfiguration = config
        playScreen = screen
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupScene() {
        let scene = SCNScene()
        self.scene = scene
        self.backgroundColor = .black
        
        // 添加相机
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene.rootNode.addChildNode(cameraNode)
        
        // 添加立方体
        let cubeNode = SCNNode(geometry: SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.1))
        scene.rootNode.addChildNode(cubeNode)
        
        // 添加光源
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 5, y: 5, z: 5)
        scene.rootNode.addChildNode(lightNode)
        
        // 允许相机控制
        self.allowsCameraControl = true
    }
}
