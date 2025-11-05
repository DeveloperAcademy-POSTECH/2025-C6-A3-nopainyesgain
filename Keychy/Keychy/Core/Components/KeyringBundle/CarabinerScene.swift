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
    
    // MARK: - 크기 조절 관련
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
            // 물리 시뮬레이션 활성화 (안정성을 위해 속도 조금 줄임)
            physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
            physicsWorld.speed = 0.8  // 1.0 → 0.8로 줄여서 안정성 증대
        } else {
            // 물리 시뮬레이션 비활성화 (BundleAddKeyringView용)
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)
            physicsWorld.speed = 0
        }
        
        // 컨테이너 없이 직접 씬에서 관리
        
        setupCarabinerWithKeyrings()
        
        // 씬 로딩 완료 후 콜백 호출
        DispatchQueue.main.async {
            self.onSceneReady?()
        }
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
        
        // 컨테이너 없이 직접 카라비너의 위치와 크기 계산
        let carabinerWidth = carabiner.size.width * scaleFactor
        let carabinerHeight = carabiner.size.height * scaleFactor
        
        // SpriteKit 좌표계 (원점: 왼쪽 아래) → SwiftUI 좌표계 (원점: 왼쪽 위) 변환
        let swiftUIY = size.height - carabiner.position.y - carabinerHeight / 2
        
        return CGRect(
            x: carabiner.position.x - carabinerWidth / 2,
            y: swiftUIY,
            width: carabinerWidth,
            height: carabinerHeight
        )
    }
    
    // MARK: - 기본 씬 설정
    func setupBasicConfiguration() {
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }
}
