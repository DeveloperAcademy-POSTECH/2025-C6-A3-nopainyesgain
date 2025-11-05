//
//  MultiKeyringScene.swift
//  Keychy
//
//  Created by Assistant on 11/05/25.
//

import SwiftUI
import SpriteKit
import Combine

/// 여러 키링을 하나의 씬에 배치하는 Scene
class MultiKeyringScene: SKScene {

    // MARK: - Properties

    /// 키링 데이터 구조체
    struct KeyringData: Equatable {
        let index: Int
        let position: CGPoint  // 화면 좌표
        let bodyImageURL: String
        let soundId: String  // 사운드 ID
        let customSoundURL: URL?  // 커스텀 녹음 파일 URL
        let particleId: String  // 파티클 ID
    }

    var keyringDataList: [KeyringData] = []
    var keyringNodes: [Int: SKNode] = [:]  // index: keyring node

    // MARK: - 키링별 구성 요소 저장
    var ringNodes: [Int: SKSpriteNode] = [:]
    var chainNodesByKeyring: [Int: [SKSpriteNode]] = [:]
    var bodyNodes: [Int: SKNode] = [:]

    // MARK: - 키링별 사운드 정보 저장
    var soundIdsByKeyring: [Int: String] = [:]  // index: soundId
    var customSoundURLsByKeyring: [Int: URL] = [:]  // index: customSoundURL

    // MARK: - 키링별 파티클 정보 저장
    var particleIdsByKeyring: [Int: String] = [:]  // index: particleId

    // MARK: - 파티클 효과 콜백
    var onPlayParticleEffect: ((Int, String, CGPoint) -> Void)?  // (keyringIndex, effectName, position)

    // MARK: - 선택된 타입들
    var currentRingType: RingType = .basic
    var currentChainType: ChainType = .basic

    // MARK: - 배경색 설정
    var customBackgroundColor: UIColor = .clear

    // MARK: - 스와이프 제스처 관련
    var lastTouchLocation: CGPoint?
    var lastTouchTime: TimeInterval = 0
    var swipeStartLocation: CGPoint?
    var lastParticleTime: TimeInterval = 0

    // MARK: - Init
    init(
        keyringDataList: [KeyringData],
        ringType: RingType = .basic,
        chainType: ChainType = .basic,
        backgroundColor: UIColor = .clear
    ) {
        self.keyringDataList = keyringDataList
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.customBackgroundColor = backgroundColor

        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        removeAllChildren()
        removeAllActions()
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = customBackgroundColor
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        setupKeyrings()
    }

    // MARK: - Setup

    /// 모든 키링 설정
    private func setupKeyrings() {
        for (order, data) in keyringDataList.enumerated() {
            setupSingleKeyring(data: data, order: order)
        }
    }

    /// 단일 키링 설정
    private func setupSingleKeyring(data: KeyringData, order: Int) {
        // 사운드 정보 저장
        soundIdsByKeyring[data.index] = data.soundId
        if let customURL = data.customSoundURL {
            customSoundURLsByKeyring[data.index] = customURL
        }

        // 파티클 정보 저장
        particleIdsByKeyring[data.index] = data.particleId

        // 좌표 변환: SwiftUI 좌표 -> SpriteKit 좌표
        let spriteKitPosition = convertToSpriteKitCoordinates(data.position)

        // 각 키링 그룹에 고유한 categoryBitMask 설정 (충돌 방지)
        let categoryBitMask: UInt32 = UInt32(1 << data.index)
        let collisionBitMask: UInt32 = categoryBitMask  // 자기 그룹 내에서만 충돌

        // zPosition 계산: 생성 순서대로 레이어링 (나중에 생성된 것이 위에)
        let baseZPosition = CGFloat(order * 10)

        // 1. Ring 생성 (KeyringScene과 동일하게 직접 씬에 추가)
        KeyringRingComponent.createNode(from: currentRingType) { [weak self] ring in
            guard let self = self, let ring = ring else {
                return
            }

            ring.position = spriteKitPosition
            ring.zPosition = baseZPosition  // Ring이 가장 뒤
            ring.physicsBody?.isDynamic = false
            ring.physicsBody?.categoryBitMask = categoryBitMask
            ring.physicsBody?.collisionBitMask = collisionBitMask
            ring.physicsBody?.contactTestBitMask = 0
            self.addChild(ring)

            // Ring 노드 저장
            self.ringNodes[data.index] = ring
            self.keyringNodes[data.index] = ring

            // 2. Chain 생성
            self.setupChain(
                ring: ring,
                centerX: spriteKitPosition.x,
                bodyImageURL: data.bodyImageURL,
                index: data.index,
                baseZPosition: baseZPosition
            )
        }
    }

    /// Chain 생성
    private func setupChain(
        ring: SKSpriteNode,
        centerX: CGFloat,
        bodyImageURL: String,
        index: Int,
        baseZPosition: CGFloat
    ) {
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY + 0.5
        let chainSpacing: CGFloat = 16

        KeyringChainComponent.createLinks(
            from: currentChainType,
            count: 5,
            startPosition: CGPoint(x: centerX, y: chainStartY),
            spacing: chainSpacing
        ) { [weak self] chains in
            guard let self = self else { return }

            // 각 체인에 고유한 물리 마스크 적용
            let categoryBitMask: UInt32 = UInt32(1 << index)
            let collisionBitMask: UInt32 = categoryBitMask

            for (chainIndex, chain) in chains.enumerated() {
                chain.zPosition = baseZPosition + 2 + CGFloat(chainIndex)  // Chain은 Body 위
                chain.physicsBody?.categoryBitMask = categoryBitMask
                chain.physicsBody?.collisionBitMask = collisionBitMask
                chain.physicsBody?.contactTestBitMask = 0
                self.addChild(chain)
            }

            // Chain 노드 저장
            self.chainNodesByKeyring[index] = chains

            // 3. Body 생성
            self.setupBody(
                ring: ring,
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                bodyImageURL: bodyImageURL,
                index: index,
                baseZPosition: baseZPosition
            )
        }
    }

    /// Body 생성
    private func setupBody(
        ring: SKSpriteNode,
        chains: [SKSpriteNode],
        centerX: CGFloat,
        chainStartY: CGFloat,
        chainSpacing: CGFloat,
        bodyImageURL: String,
        index: Int,
        baseZPosition: CGFloat
    ) {
        KeyringBodyComponent.createNode(from: bodyImageURL) { [weak self] body in
            guard let self = self, let body = body else { return }

            self.positionAndConnectBody(
                body: body,
                ring: ring,
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                index: index,
                baseZPosition: baseZPosition
            )
        }
    }

    /// Body 위치 설정 및 연결
    private func positionAndConnectBody(
        body: SKNode,
        ring: SKSpriteNode,
        chains: [SKSpriteNode],
        centerX: CGFloat,
        chainStartY: CGFloat,
        chainSpacing: CGFloat,
        index: Int,
        baseZPosition: CGFloat
    ) {
        let bodyFrame = body.calculateAccumulatedFrame()
        let bodyHalfHeight = bodyFrame.height / 2

        let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
        let lastLinkHeight: CGFloat = chains.last.map { $0.calculateAccumulatedFrame().height } ?? chainSpacing
        let lastChainBottomY = lastChainY - lastLinkHeight / 2

        let connectGap = 30.0
        let bodyCenterY = lastChainBottomY - bodyHalfHeight + connectGap

        body.position = CGPoint(x: centerX, y: bodyCenterY)
        body.zPosition = baseZPosition + 1  // Body는 Ring 바로 위

        // Body에 고유한 물리 마스크 적용
        let categoryBitMask: UInt32 = UInt32(1 << index)
        let collisionBitMask: UInt32 = categoryBitMask
        body.physicsBody?.categoryBitMask = categoryBitMask
        body.physicsBody?.collisionBitMask = collisionBitMask
        body.physicsBody?.contactTestBitMask = 0

        addChild(body)

        // Body 노드 저장
        bodyNodes[index] = body

        // 조인트 연결
        connectComponents(ring: ring, chains: chains, body: body)
    }

    /// 키링 구성 요소들을 Joint로 연결
    private func connectComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        var previousNode: SKNode = ring

        // Ring과 첫 번째 Chain 연결
        if let firstChain = chains.first {
            let anchorY = previousNode.position.y

            let joint = SKPhysicsJointPin.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchor: CGPoint(
                    x: (ring.position.x + firstChain.position.x) / 2,
                    y: anchorY
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.1
            physicsWorld.add(joint)

            let distance = hypot(
                firstChain.position.x - ring.position.x,
                firstChain.position.y - ring.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = distance * 1.05
            physicsWorld.add(limitJoint)

            firstChain.physicsBody?.linearDamping = 0.5
            firstChain.physicsBody?.angularDamping = 0.5

            previousNode = firstChain
        }

        // Chain 링크들 연결
        for i in 1..<chains.count {
            let current = chains[i]
            if let previous = previousNode.physicsBody {
                let joint = SKPhysicsJointPin.joint(
                    withBodyA: previous,
                    bodyB: current.physicsBody!,
                    anchor: CGPoint(
                        x: (previousNode.position.x + current.position.x) / 2,
                        y: (previousNode.position.y + current.position.y) / 2
                    )
                )
                joint.shouldEnableLimits = false
                joint.frictionTorque = 0.1
                physicsWorld.add(joint)

                let distance = hypot(
                    current.position.x - previousNode.position.x,
                    current.position.y - previousNode.position.y
                )
                let limitJoint = SKPhysicsJointLimit.joint(
                    withBodyA: previous,
                    bodyB: current.physicsBody!,
                    anchorA: CGPoint.zero,
                    anchorB: CGPoint.zero
                )
                limitJoint.maxLength = distance * 1.05
                physicsWorld.add(limitJoint)

                current.physicsBody?.linearDamping = 0.05
                current.physicsBody?.angularDamping = 0.05
            }
            previousNode = current
        }

        // 마지막 Chain과 Body 연결
        if let lastChain = chains.last, let bodyPhysics = body.physicsBody {
            let joint = SKPhysicsJointFixed.joint(
                withBodyA: lastChain.physicsBody!,
                bodyB: bodyPhysics,
                anchor: CGPoint(
                    x: lastChain.position.x,
                    y: lastChain.position.y
                )
            )
            physicsWorld.add(joint)

            let distance = hypot(
                body.position.x - lastChain.position.x,
                body.position.y - lastChain.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: lastChain.physicsBody!,
                bodyB: bodyPhysics,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = distance * 1.05
            physicsWorld.add(limitJoint)

            bodyPhysics.linearDamping = 0.5
            bodyPhysics.angularDamping = 0.5
        }
    }

    // MARK: - Helper Methods

    /// SwiftUI 좌표를 SpriteKit 좌표로 변환
    private func convertToSpriteKitCoordinates(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x, y: size.height - point.y)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        lastTouchLocation = location
        lastTouchTime = touch.timestamp
        swipeStartLocation = location

        Haptic.impact(style: .medium)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
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

                // 모든 키링에 스와이프 힘 적용
                applySwipeForceToAllKeyrings(at: location, velocity: velocity)

                // 일정 속도 이상 스와이프 시 파티클 효과 발사 (쓰로틀링 0.3초)
                let speed = hypot(velocity.dx, velocity.dy)
                if speed > 2500 && (touch.timestamp - lastParticleTime) > 0.3 {
                    applyParticleEffectNearLocation(at: location)
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

        // 거리 계산
        if let start = swipeStartLocation {
            let distance = hypot(end.x - start.x, end.y - start.y)

            // 탭 감지: 거리가 짧으면 사운드 효과 실행
            if distance < 30 {
                // 어떤 바디가 탭되었는지 확인
                for (index, body) in bodyNodes {
                    if body.contains(end) {
                        // 해당 키링의 사운드 재생
                        if let soundId = soundIdsByKeyring[index] {
                            applySoundEffect(soundId: soundId, index: index)
                        }
                        break
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

    // MARK: - Sound Effect

    /// 사운드 효과 재생 (KeyringScene+Effects와 동일)
    func applySoundEffect(soundId: String, index: Int) {
        guard soundId != "none" else { return }

        // Firebase Storage URL인 경우 (커스텀 사운드가 저장된 경우)
        if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
            if let url = URL(string: soundId) {
                SoundEffectComponent.shared.playSound(from: url)
            }
            return
        }

        // 로컬 커스텀 녹음 파일인 경우
        if soundId == "custom_recording", let customURL = customSoundURLsByKeyring[index] {
            SoundEffectComponent.shared.playSound(from: customURL)
            return
        }

        // 일반 사운드 파일
        SoundEffectComponent.shared.playSound(named: soundId)
    }

    // MARK: - Particle Effect

    /// 특정 위치 근처의 키링에 파티클 효과 적용
    private func applyParticleEffectNearLocation(at location: CGPoint) {
        // 가장 가까운 키링 찾기
        var closestIndex: Int?
        var closestDistance: CGFloat = .infinity

        for (index, body) in bodyNodes {
            let bodyCenter = body.position
            let distance = hypot(location.x - bodyCenter.x, location.y - bodyCenter.y)

            if distance < 100 && distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        // 가장 가까운 키링의 파티클 효과 발생
        if let index = closestIndex,
           let particleId = particleIdsByKeyring[index],
           particleId != "none",
           let body = bodyNodes[index] {
            onPlayParticleEffect?(index, particleId, body.position)
        }
    }

    // MARK: - Swipe Force Application

    private func applySwipeForceToAllKeyrings(at location: CGPoint, velocity: CGVector) {
        for (index, chains) in chainNodesByKeyring {
            guard let body = bodyNodes[index] else { continue }

            // Body 중심 기준으로 스와이프 적용
            let bodyCenter = body.position
            let distance = hypot(location.x - bodyCenter.x, location.y - bodyCenter.y)

            // Body 근처에서만 힘 적용 (거리가 가까울수록 강한 힘)
            if distance < 50 {
                let force = CGVector(
                    dx: velocity.dx * 0.3,
                    dy: velocity.dy * 0.3
                )

                // 각 체인에 힘 적용
                for chain in chains {
                    chain.physicsBody?.applyImpulse(force)
                }

                // Body에도 힘 적용
                body.physicsBody?.applyImpulse(force)
            }
        }
    }
}
