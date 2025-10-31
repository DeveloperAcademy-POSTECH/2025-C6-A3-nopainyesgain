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
    var cachedImages: KeyringImages?
    var isReady: Bool = false
    
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
        backgroundColor = .gray50
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        containerNode = SKNode()
        containerNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        containerNode.setScale(scaleFactor)
        addChild(containerNode)

        setupKeyring()
    }
    

    func updateForNewSize(_ newSize: CGSize, zoomScale: CGFloat) {
        // 1. 물리 세계 일시 정지
        physicsWorld.speed = 0
        self.isReady = false
        
        // 2. 현재 상태 확인
        let scaleX = newSize.width / originalSize.width
        let scaleY = newSize.height / originalSize.height
        let newScaleFactor = min(scaleX, scaleY) * zoomScale
        
        let currentScale = containerNode.xScale
        let isScalingUp = newScaleFactor > currentScale
        
        // 3. ⭐️ 확대/축소에 따른 전략 분기
        if isScalingUp {
            // ===== 확대 시: 위에서 아래로 부드럽게 =====
            
            // 3-1. 현재 containerNode를 fade out
            let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.15)
            containerNode.run(fadeOut) { [weak self] in
                guard let self = self else { return }
                
                // 3-2. 투명한 상태에서 노드 재조립
                self.containerNode.removeAllChildren()
                self.containerNode.removeAllActions()
                
                self.size = newSize
                
                // 3-3. 위쪽 시작 위치 설정
                let finalPosition = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
                let startOffset: CGFloat = 60
                let startPosition = CGPoint(x: finalPosition.x, y: finalPosition.y - startOffset)
                
                self.containerNode.position = startPosition
                self.containerNode.setScale(newScaleFactor)
                self.containerNode.alpha = 0 // 투명 상태 유지
                
                // 3-4. 키링 재조립 (이미지는 캐시됨)
                self.setupKeyring()
                
                // 3-5. 재조립 완료 후 애니메이션으로 등장
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // 위치 이동
                    let moveDown = SKAction.move(to: finalPosition, duration: 0.4)
                    moveDown.timingMode = .easeOut
                    
                    // 페이드 인
                    let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
                    fadeIn.timingMode = .easeOut
                    
                    let appear = SKAction.group([moveDown, fadeIn])
                    
                    self.containerNode.run(appear) {
                        self.physicsWorld.speed = 1.0
                    }
                }
            }
            
        } else {
            // ===== 축소 시: 위쪽으로 축소 (기존 방식) =====
            
            containerNode.removeAllChildren()
            containerNode.removeAllActions()
            
            size = newSize
            containerNode.position = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
            containerNode.setScale(newScaleFactor)
            
            // 키링 재조립
            setupKeyring()
            
            // 물리 재개
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.physicsWorld.speed = 1.0
            }
        }
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
        
        // ⭐️ 기본 감도 설정 (KeyringScene과 동일하게)
        let baseForceMagnitude: CGFloat = 0.3
        
        // ⭐️ scaleFactor에 따른 보정
        // containerNode가 확대되어 있으면 힘을 줄이고, 축소되어 있으면 힘을 늘림
        let scaledForceMagnitude = baseForceMagnitude / scaleFactor
        
        // 체인에 힘 적용
        for chainNode in chainNodes {
            let force = CGVector(
                dx: velocity.dx * scaledForceMagnitude * 0.3,
                dy: velocity.dy * scaledForceMagnitude * 0.3
            )
            chainNode.physicsBody?.applyImpulse(force)
        }
        
        // Body에도 힘 적용
        let bodyForce = CGVector(
            dx: velocity.dx * scaledForceMagnitude * 0.5,
            dy: velocity.dy * scaledForceMagnitude * 0.5
        )
        body.physicsBody?.applyImpulse(bodyForce)
    }
    
    // MARK: - 터치 인터랙션
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isReady else { return } // ⭐️ 로딩 완료 전에는 터치 무시
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let localLocation = containerNode.convert(location, from: self)
        
        lastTouchLocation = localLocation
        lastTouchTime = touch.timestamp
        swipeStartLocation = localLocation
        
        Haptic.impact(style: .medium)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isReady else { return } // ⭐️ 로딩 완료 전에는 터치 무시
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let localLocation = containerNode.convert(location, from: self)
        
        if let lastLocation = lastTouchLocation {
            let deltaX = localLocation.x - lastLocation.x
            let deltaY = localLocation.y - lastLocation.y
            let deltaTime = touch.timestamp - lastTouchTime
            
            if deltaTime > 0 {
                let velocityX = deltaX / CGFloat(deltaTime)
                let velocityY = deltaY / CGFloat(deltaTime)
                let velocity = CGVector(dx: velocityX, dy: velocityY)
                
                applySwipeForceToNearbyChains(at: localLocation, velocity: velocity)
                
                let speed = hypot(velocity.dx, velocity.dy)
                if speed > 2500 && (touch.timestamp - lastParticleTime) > 0.3 {
                    applyParticleEffect(particleId: currentParticleId)
                    lastParticleTime = touch.timestamp
                }
            }
        }
        
        lastTouchLocation = localLocation
        lastTouchTime = touch.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isReady else { return } // ⭐️ 로딩 완료 전에는 터치 무시
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let localLocation = containerNode.convert(location, from: self)
        
        if let start = swipeStartLocation {
            let distance = hypot(localLocation.x - start.x, localLocation.y - start.y)
            
            if distance < 30 {
                if let body = bodyNode {
                    let bodyFrame = body.frame
                    if bodyFrame.contains(localLocation) {
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
