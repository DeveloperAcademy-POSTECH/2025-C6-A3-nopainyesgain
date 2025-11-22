//
//  KeyringDetailScene.swift
//  Keychy
//
//  Created by Jini on 10/31/25.
//

import SpriteKit

// 키링 상세보기용
class KeyringDetailScene: SKScene {
    
    // MARK: - Properties
    var bodyImage: String?
    var hookOffsetY: CGFloat?
    var chainLength: Int = 5  // 체인 링크 개수 (기본값 5)
    var onLoadingComplete: (() -> Void)?
    var cachedImages: KeyringImages?
    var isReady: Bool = false

    // MARK: - 효과 ID 저장용
    var currentSoundId: String = "none"
    var currentParticleId: String = "none"

    // MARK: - 선택된 타입들
    var currentRingType: RingType
    var currentChainType: ChainType
    
    // MARK: - 구성 요소들
    weak var ringNode: SKSpriteNode?
    var chainNodes: [SKSpriteNode] = []
    weak var bodyNode: SKNode?
    
    // MARK: - 스와이프 제스처 관련
    var lastTouchLocation: CGPoint?
    var lastTouchTime: TimeInterval = 0
    var swipeStartLocation: CGPoint?
    
    // MARK: - 이펙트 쓰로틀링
    var lastParticleTime: TimeInterval = 0
    
    // MARK: - SwiftUI로 파티클 효과 콜백 전달용
    var onPlayParticleEffect: ((String) -> Void)?
    
    // MARK: - 터치 인터랙션 활성화 여부
    var isTouchEnabled: Bool = true
    
    // TODO: originalSize을 실행 중인 기기 사이즈로 설정 필요
    let originalSize = CGSize(width: 393, height: 852)
    
    // MARK: - Init / Deinit
    // zoomScale : 확대 비율
    init(
        ringType: RingType,
        chainType: ChainType,
        bodyImage: String? = nil,
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

        super.init(size: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        setupKeyring()
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        cleanup()
    }
    
    // MARK: - 메모리 정리
    private func cleanup() {
        // 콜백 제거
        onLoadingComplete = nil
        onPlayParticleEffect = nil
        
        // 노드 참조 제거
        ringNode = nil
        chainNodes.removeAll()
        bodyNode = nil
        
        // 캐시된 이미지 제거
        cachedImages = nil
        
        // 모든 액션과 노드 제거
        removeAllChildren()
        removeAllActions()
        
        // Physics World 정리
        physicsWorld.removeAllJoints()
    }
    
    func applySoundEffect(soundId: String) {
        guard soundId != "none", isReady else { return }

        if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
            if let url = URL(string: soundId) {
                SoundEffectComponent.shared.playSound(from: url)
            }
            return
        }

        SoundEffectComponent.shared.playSound(named: soundId)
    }
    
    func applyParticleEffect(particleId: String) {
        guard particleId != "none", isReady else { return }
        
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastParticleTime >= 0.5 else { return }
        lastParticleTime = currentTime
        
        onPlayParticleEffect?(particleId)
    }
    
    private func applySwipeForceToNearbyChains(at location: CGPoint, velocity: CGVector) {
        guard let body = bodyNode, isReady else { return }
        
        let forceMagnitude: CGFloat = 0.6
        
        for chainNode in chainNodes {
            let force = CGVector(
                dx: velocity.dx * forceMagnitude * 0.3,
                dy: velocity.dy * forceMagnitude * 0.3
            )
            chainNode.physicsBody?.applyImpulse(force)
        }
        
        let bodyForce = CGVector(
            dx: velocity.dx * forceMagnitude * 0.5,
            dy: velocity.dy * forceMagnitude * 0.5
        )
        body.physicsBody?.applyImpulse(bodyForce)
    }
    
    // MARK: - 터치 인터랙션
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchEnabled, isReady, isPaused == false else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        lastTouchLocation = location
        lastTouchTime = touch.timestamp
        swipeStartLocation = location
        
        Haptic.impact(style: .medium)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchEnabled, isReady, isPaused == false else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let lastLocation = lastTouchLocation {
            let deltaX = location.x - lastLocation.x
            let deltaY = location.y - lastLocation.y
            let deltaTime = touch.timestamp - lastTouchTime
            
            if deltaTime > 0 {
                let velocityX = deltaX / CGFloat(deltaTime)
                let velocityY = deltaY / CGFloat(deltaTime)
                let velocity = CGVector(dx: velocityX, dy: velocityY)
                
                applySwipeForceToNearbyChains(at: location, velocity: velocity)
                
                let speed = hypot(velocity.dx, velocity.dy)
                if speed > 1200 && (touch.timestamp - lastParticleTime) > 0.3 {
                    applyParticleEffect(particleId: currentParticleId)
                    lastParticleTime = touch.timestamp
                }
            }
        }
        
        lastTouchLocation = location
        lastTouchTime = touch.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchEnabled, isReady, isPaused == false else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let start = swipeStartLocation {
            let distance = hypot(location.x - start.x, location.y - start.y)
            
            if distance < 30 {
                if let body = bodyNode {
                    let bodyFrame = body.frame
                    if bodyFrame.contains(location) {
                        applySoundEffect(soundId: currentSoundId)
                    }
                }
            }
        }
        
        swipeStartLocation = nil
        lastTouchLocation = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        swipeStartLocation = nil
        lastTouchLocation = nil
    }

}
