//  CarabinerPreviewScene.swift
//  Keychy

import SpriteKit
import UIKit

final class CarabinerPreviewScene: SKScene {
    // 기준 기기 사이즈
    private let originalSize = CGSize(width: 393, height: 852)
    
    // 스케일 적용용 컨테이너
    private var containerNode = SKNode()
    private var scaleFactor: CGFloat = 1.0
    
    // 데이터
    private var carabinerImage: UIImage?
    private var carabinerNode: SKSpriteNode?
    
    // 키링 포인트 비율 (0~1)
    private var keyringXPositions: [CGFloat] = []
    private var keyringYPositions: [CGFloat] = []
    private var keyringPointNodes: [SKNode] = []
    
    init(targetSize: CGSize, carabinerImage: UIImage? = nil) {
        self.carabinerImage = carabinerImage
        super.init(size: targetSize)
        self.scaleMode = .resizeFill
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
    }
    
    deinit {
        removeAllChildren()
        removeAllActions()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        physicsWorld.speed = 0
        
        addChild(containerNode)
        containerNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        let scaleX = size.width / originalSize.width
        let scaleY = size.height / originalSize.height
        scaleFactor = min(scaleX, scaleY)
        containerNode.setScale(scaleFactor)
        
        assembleCarabiner()
        renderKeyringPoints()
    }
    
    func updateSize(_ newSize: CGSize) {
        self.size = newSize
        let scaleX = newSize.width / originalSize.width
        let scaleY = newSize.height / originalSize.height
        scaleFactor = min(scaleX, scaleY)
        containerNode.position = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
        containerNode.setScale(scaleFactor)
        positionCarabiner()
        renderKeyringPoints()
    }
    
    func updateCarabinerImage(_ image: UIImage?) {
        self.carabinerImage = image
        assembleCarabiner()
        renderKeyringPoints()
    }
    
    func updateKeyringPositions(x: [CGFloat], y: [CGFloat]) {
        self.keyringXPositions = x
        self.keyringYPositions = y
        renderKeyringPoints()
    }
    
    private func assembleCarabiner() {
        carabinerNode?.removeFromParent()
        
        let node = SKSpriteNode()
        if let img = carabinerImage {
            node.texture = SKTexture(image: img)
            // 화면 가로의 0.5배로 카라비너 크기 설정 (BundleAddKeyringView와 동일)
            let screenWidth: CGFloat = originalSize.width
            let carabinerWidth = screenWidth * 0.5
            let aspectRatio = img.size.height / img.size.width
            let carabinerHeight = carabinerWidth * aspectRatio
            node.size = CGSize(width: carabinerWidth, height: carabinerHeight)
        }
        node.physicsBody = nil
        containerNode.addChild(node)
        carabinerNode = node
        
        positionCarabiner()
    }
    
    private func positionCarabiner() {
        guard let node = carabinerNode else { return }
        // CarabinerScene+SetUp.swift와 동일한 위치 (line 18)
        let topY = originalSize.height * 0.3
        node.position = CGPoint(x: 0, y: topY)
        node.zPosition = 0
    }
    
    // + 버튼 포인트 렌더
    private func renderKeyringPoints() {
        // 기존 포인트 제거
        for n in keyringPointNodes { n.removeFromParent() }
        keyringPointNodes.removeAll()
        
        guard let carabinerNode = carabinerNode else { return }
        let carabinerSize = carabinerNode.size
        
        // 카라비너 노드 중심 기준으로 비율 좌표를 실제 좌표로 변환
        for i in 0..<min(keyringXPositions.count, keyringYPositions.count) {
            let nx = keyringXPositions[i]  // 0~1
            let ny = keyringYPositions[i]  // 0~1 (SpriteKit 기준: 0=아래, 1=위)
            
            let xOffset = (nx - 0.5) * carabinerSize.width
            let yOffset = (ny - 0.5) * carabinerSize.height
            
            // 간단한 원형 포인트 (필요 시 에셋으로 교체)
            let point = SKShapeNode(circleOfRadius: 10)
            point.fillColor = .white
            point.strokeColor = .clear
            point.alpha = 0.9
            point.position = CGPoint(x: carabinerNode.position.x + xOffset,
                                     y: carabinerNode.position.y + yOffset)
            point.zPosition = 1 // 카라비너 위
            
            containerNode.addChild(point)
            keyringPointNodes.append(point)
        }
    }
}
