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
    var onLoadingComplete: (() -> Void)?
    
    // MARK: - 효과 ID 저장용
    var currentSoundId: String = "none"
    var currentParticleId: String = "none"
    
    // MARK: - 선택된 타입들
    var currentRingType: RingType
    var currentChainType: ChainType
    
    // MARK: - 구성 요소들
    var ringNode: SKSpriteNode?
    var chainNodes: [SKSpriteNode] = []
    var bodyNode: SKNode?
    
    // MARK: - 스와이프 제스처 관련
    var lastTouchLocation: CGPoint?
    var lastTouchTime: TimeInterval = 0
    var swipeStartLocation: CGPoint?
    
    // MARK: - 이펙트 쓰로틀링
    var lastParticleTime: TimeInterval = 0
    
    // MARK: - SwiftUI로 파티클 효과 콜백 전달용
    var onPlayParticleEffect: ((String) -> Void)?
    
    // MARK: - 크기 조절용 컨테이너 노드
    var containerNode: SKNode!
    let scaleFactor: CGFloat // 크기 비율
    
    // TODO: originalSize을 실행 중인 기기 사이즈로 설정 필요
    let originalSize = CGSize(width: 393, height: 852)
    
    // MARK: - Init / Deinit
    // zoomScale : 확대 비율
    init(
        ringType: RingType,
        chainType: ChainType,
        bodyImage: String? = nil,
        targetSize: CGSize,
        zoomScale: CGFloat = 1.5,
        onLoadingComplete: (() -> Void)? = nil
    ) {
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.bodyImage = bodyImage
        self.onLoadingComplete = onLoadingComplete
        
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
        backgroundColor = .white100
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        containerNode = SKNode()
        containerNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        containerNode.setScale(scaleFactor)
        addChild(containerNode)

        setupKeyring()
    }
    
    // MARK: - 사운드 효과 적용
    func applySoundEffect(soundId: String) {
        guard soundId != "none" else { return }
        
        // SoundEffect enum으로 변환
        
        SoundEffectComponent.shared.playSound(named: soundId)
    }
    
    // MARK: - 파티클 효과 적용
    func applyParticleEffect(particleId: String) {
        guard particleId != "none" else { return }
        
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastParticleTime >= 0.5 else { return } // 쓰로틀링
        lastParticleTime = currentTime
        
        onPlayParticleEffect?(particleId)
    }
    
    // MARK: - 스와이프 힘 적용
    private func applySwipeForceToNearbyChains(at location: CGPoint, velocity: CGVector) {
        guard let body = bodyNode else { return }
        
        let forceMagnitude: CGFloat = 0.3
        
        // 체인에 힘 적용
        for chainNode in chainNodes {
            let force = CGVector(
                dx: velocity.dx * forceMagnitude * 0.3,
                dy: velocity.dy * forceMagnitude * 0.3
            )
            chainNode.physicsBody?.applyImpulse(force)
        }
        
        // Body에도 힘 적용
        let bodyForce = CGVector(
            dx: velocity.dx * forceMagnitude * 0.5,
            dy: velocity.dy * forceMagnitude * 0.5
        )
        body.physicsBody?.applyImpulse(bodyForce)
    }
    
    // MARK: - 터치 인터랙션
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        lastTouchLocation = location
        lastTouchTime = touch.timestamp
        swipeStartLocation = location
        
        // 탭 햅틱
        Haptic.impact(style: .medium)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let lastLocation = lastTouchLocation {
            // 스와이프 방향과 속도 계산
            let deltaX = location.x - lastLocation.x
            let deltaY = location.y - lastLocation.y
            let deltaTime = touch.timestamp - lastTouchTime
            
            if deltaTime > 0 {
                let velocityX = deltaX / CGFloat(deltaTime)
                let velocityY = deltaY / CGFloat(deltaTime)
                let velocity = CGVector(dx: velocityX, dy: velocityY)
                
                // 스와이프 힘 적용
                applySwipeForceToNearbyChains(at: location, velocity: velocity)
                
                // 일정 속도 이상 스와이프 시 파티클 효과 (쓰로틀링 0.3초)
                let speed = hypot(velocity.dx, velocity.dy)
                if speed > 2500 && (touch.timestamp - lastParticleTime) > 0.3 {
                    applyParticleEffect(particleId: currentParticleId)
                    lastParticleTime = touch.timestamp
                }
            }
        }
        
        lastTouchLocation = location
        lastTouchTime = touch.timestamp
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let end = touch.location(in: self)
        
        // 탭 감지: 거리가 짧으면 사운드 효과
        if let start = swipeStartLocation {
            let distance = hypot(end.x - start.x, end.y - start.y)
            
            if distance < 30 {
                if let body = bodyNode, body.contains(end) {
                    applySoundEffect(soundId: currentSoundId)
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
