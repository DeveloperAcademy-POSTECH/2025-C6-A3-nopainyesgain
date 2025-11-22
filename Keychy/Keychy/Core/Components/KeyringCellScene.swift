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
    var hookOffsetY: CGFloat?  // 바디 연결 지점 Y 오프셋 (nil이면 0.0 사용)
    var chainLength: Int = 5  // 체인 링크 개수 (기본값 5)

    // MARK: - 선택된 타입들
    var currentRingType: RingType
    var currentChainType: ChainType

    // MARK: - 크기 조절용 컨테이너 노드
    weak var containerNode: SKNode!
    let scaleFactor: CGFloat // 크기 비율
    let originalSize = CGSize(width: 393, height: 852) // 기준 사이즈
    
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
        hookOffsetY: CGFloat? = nil,
        chainLength: Int = 5,
        onLoadingComplete: (() -> Void)? = nil
    ) {
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.bodyImage = bodyImage
        self.hookOffsetY = hookOffsetY
        self.chainLength = chainLength
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
        cleanup()
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
        let newContainerNode = SKNode()
        newContainerNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        newContainerNode.setScale(scaleFactor)
        addChild(newContainerNode)
        containerNode = newContainerNode

        // containerNode 설정 완료 후 키링 설정
        DispatchQueue.main.async { [weak self] in
            self?.setupKeyring()
        }
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        cleanup()
    }
    
    // MARK: - 메모리 정리
    private func cleanup() {
        onLoadingComplete = nil
        containerNode = nil
        
        removeAllChildren()
        removeAllActions()
        physicsWorld.removeAllJoints()
    }
}
