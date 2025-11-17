//
//  KeyringCellScene.swift
//  KeytschPrototype
//
//  Created by Jini on 10/26/25.
//

import SpriteKit

// 컬렉션 셀 프리뷰용
class KeyringCellScene: SKScene {
    
    // MARK: - Properties
    var bodyImage: String?
    var onLoadingComplete: (() -> Void)?
    var hookOffsetY: CGFloat  // 바디 연결 지점 Y 오프셋

    // MARK: - 선택된 타입들
    var currentRingType: RingType
    var currentChainType: ChainType

    // MARK: - 크기 조절용 컨테이너 노드
    var containerNode: SKNode!
    let scaleFactor: CGFloat // 크기 비율
    // TODO: originalSize을 실행 중인 기기 사이즈로 설정 필요
    let originalSize = CGSize(width: 393, height: 852)
    
    var customBackgroundColor: UIColor = .gray50
    
    // MARK: - Init / Deinit
    // zoomScale : 확대 비율
    init(
        ringType: RingType,
        chainType: ChainType,
        bodyImage: String? = nil,
        targetSize: CGSize,
        customBackgroundColor: UIColor = .gray50,
        zoomScale: CGFloat = 1.5,
        hookOffsetY: CGFloat = 0.0,
        onLoadingComplete: (() -> Void)? = nil
    ) {
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.bodyImage = bodyImage
        self.hookOffsetY = hookOffsetY
        self.onLoadingComplete = onLoadingComplete
        self.customBackgroundColor = customBackgroundColor
        
        let scaleX = targetSize.width / originalSize.width
        let scaleY = targetSize.height / originalSize.height
        self.scaleFactor = min(scaleX, scaleY) * zoomScale

        super.init(size: targetSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeAllChildren()
        removeAllActions()
    }
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // 이미 초기화되었으면 스킵 (중복 렌더링 방지)
        guard containerNode == nil else {
            return
        }

        // 커스텀 배경색 설정
        backgroundColor = customBackgroundColor
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        // 컨테이너 설정
        containerNode = SKNode()
        containerNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        containerNode.setScale(scaleFactor)
        addChild(containerNode)

        setupKeyring()
    }
}
