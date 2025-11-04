//
//  CarabinerScene.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SpriteKit

class CarabinerScene: SKScene {
    
    // MARK: - Properties
    var carabinerImage: UIImage?  // 뒷면 이미지
    var carabinerFrontImage: UIImage?  // 앞면 이미지 (햄버거 구조용)
    var bodyImages: [UIImage] = []
    var screenWidth: CGFloat
    var carabiner: Carabiner?
    
    // MARK: - 물리 시뮬레이션 제어 플래그 🎛️
    var isPhysicsEnabled: Bool = true  // 기본값은 물리 시뮬레이션 활성화
    
    // MARK: - 씬 로딩 완료 콜백
    var onSceneReady: (() -> Void)?
    
    // MARK: - 크기 조절용 컨테이너 노드
    var containerNode: SKNode!
    let scaleFactor: CGFloat
    let originalSize = CGSize(width: 393, height: 852)
    
    /// 원본 사이즈 비율 반환 함수입니다.
    var sizeRatio: CGFloat {
        return originalSize.height / originalSize.width
    }
    
    // MARK: - 구성 요소들 (햄버거 구조)
    var carabinerNode: SKSpriteNode?  // 뒷면 카라비너
    var carabinerFrontNode: SKSpriteNode?  // 앞면 카라비너 (오버레이)
    var ringNode: SKSpriteNode?
    var chainNodes: [SKSpriteNode] = []
    var bodyNode: SKNode?
    var keyrings: [SKNode] = []
    var keyringPointNodes: [SKNode] = []  // 키링 위치 표시용 포인트들
    
    // MARK: - 선택된 타입들
    var currentRingType: RingType = .basic
    var currentChainType: ChainType = .basic
    var currentBodyType: BodyType = .basic
    
    // MARK: - 스와이프 제스처 관련
    var lastTouchLocation: CGPoint?
    var lastTouchTime: TimeInterval = 0
    var swipeStartLocation: CGPoint?
    
    // MARK: - Init
    init(
        carabiner: Carabiner?,
        carabinerImage: UIImage?,
        ringType: RingType = .basic,
        chainType: ChainType = .basic,
        bodyType: BodyType = .basic,
        bodyImages: [UIImage],
        targetSize: CGSize,
        screenWidth: CGFloat,
        zoomScale: CGFloat = 1.5,
        isPhysicsEnabled: Bool = true  // 물리 시뮬레이션 활성화 여부
    ) {
        self.carabiner = carabiner
        self.carabinerImage = carabinerImage
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.currentBodyType = bodyType
        self.bodyImages = bodyImages.map { $0.fixedOrientation() }
        self.screenWidth = screenWidth
        self.isPhysicsEnabled = isPhysicsEnabled  // 물리 시뮬레이션 설정 저장
        
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
        backgroundColor = .clear

        // 물리 시뮬레이션 설정 분기 처리
        if isPhysicsEnabled {
            // 물리 시뮬레이션 활성화 (다른 뷰들용)
            physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
            physicsWorld.speed = 1.0
        } else {
            // 물리 시뮬레이션 비활성화 (BundleAddKeyringView용)
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)
            physicsWorld.speed = 0
        }

        // 컨테이너 설정
        containerNode = SKNode()
        containerNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        containerNode.setScale(scaleFactor)
        addChild(containerNode)

        setupCarabinerWithKeyrings()

        // onSceneReady는 createKeyringsAsync에서 호출됨 (중복 호출 제거)
    }
    
    // MARK: - 접근자 메서드들
    
    /// 특정 인덱스의 키링 가져오기
    func getKeyring(at index: Int) -> SKNode? {
        guard index >= 0 && index < keyrings.count else { return nil }
        return keyrings[index]
    }
    
    /// 모든 키링 가져오기
    func getAllKeyrings() -> [SKNode] {
        return keyrings
    }
    
    /// 카라비너 가져오기
    func getCarabiner() -> SKSpriteNode? {
        return carabinerNode
    }
    
    /// 카라비너의 프레임 정보 반환 (SwiftUI 좌표계로 변환)
    func getCarabinerFrame() -> CGRect? {
        guard let carabiner = carabinerNode else { return nil }
        
        // 카라비너의 월드 좌표와 크기 계산
        let worldPos = containerNode.convert(carabiner.position, to: self)
        let carabinerWidth = carabiner.size.width * scaleFactor
        let carabinerHeight = carabiner.size.height * scaleFactor
        
        // SpriteKit 좌표계 (원점: 왼쪽 아래) → SwiftUI 좌표계 (원점: 왼쪽 위) 변환
        let swiftUIY = size.height - worldPos.y - carabinerHeight / 2
        
        return CGRect(
            x: worldPos.x - carabinerWidth / 2,
            y: swiftUIY,
            width: carabinerWidth,
            height: carabinerHeight
        )
    }
    
    // MARK: - 카라비너 업데이트 (BundleSelectCarabinerView용)
    func updateCarabiner(carabiner: Carabiner, image: UIImage) {
        // containerNode가 아직 초기화되지 않았으면 리턴
        guard containerNode != nil else {
            print("⚠️ containerNode가 아직 초기화되지 않았습니다.")
            return
        }

        // 카라비너 데이터 업데이트
        self.carabiner = carabiner
        self.carabinerImage = image

        // 기존 카라비너 노드 제거
        carabinerNode?.removeFromParent()
        carabinerFrontNode?.removeFromParent()

        // 새 카라비너 생성 및 배치
        let centerX: CGFloat = 0
        let topY = originalSize.height * 0.3

        let backCarabiner = createCarabiner()
        backCarabiner.position = CGPoint(x: centerX, y: topY)
        backCarabiner.physicsBody?.isDynamic = false
        containerNode.addChild(backCarabiner)
        carabinerNode = backCarabiner

        // 키링 포인트 렌더링
        renderKeyringPoints()
    }

    // MARK: - 키링 포인트 렌더링 (BundleSelectCarabinerView용)
    func renderKeyringPoints() {
        // 기존 포인트 제거
        keyringPointNodes.forEach { $0.removeFromParent() }
        keyringPointNodes.removeAll()

        guard let carabiner = carabiner,
              let carabinerNode = carabinerNode else { return }

        let carabinerSize = carabinerNode.size

        // 카라비너 노드 중심 기준으로 비율 좌표를 실제 좌표로 변환
        for i in 0..<min(carabiner.keyringXPosition.count, carabiner.keyringYPosition.count) {
            let nx = carabiner.keyringXPosition[i]  // 0~1
            let ny = carabiner.keyringYPosition[i]  // 0~1 (SpriteKit 기준: 0=아래, 1=위)

            let xOffset = (nx - 0.5) * carabinerSize.width
            let yOffset = (ny - 0.5) * carabinerSize.height

            // 간단한 원형 포인트
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
