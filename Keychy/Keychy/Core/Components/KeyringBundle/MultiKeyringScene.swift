//
//  MultiKeyringScene.swift
//  Keychy
//
//  Created by rundo on 11/05/25.
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

    // MARK: - 씬 준비 완료 콜백
    var onAllKeyringsReady: (() -> Void)?  // 모든 키링 안정화 완료 콜백

    // MARK: - 선택된 타입들
    var currentCarabinerType: CarabinerType?
    var currentRingType: RingType = .basic
    var currentChainType: ChainType = .basic

    // MARK: - 배경색 및 이미지 설정
    var customBackgroundColor: UIColor = .clear
    var backgroundImageURL: String?  // 배경 이미지 URL
    var carabinerBackImageURL: String?  // 카라비너 뒷면 이미지 (hamburger 타입)
    var carabinerFrontImageURL: String?  // 카라비너 앞면 이미지 (hamburger 타입)

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
        backgroundColor: UIColor = .clear,
        backgroundImageURL: String? = nil,
        carabinerBackImageURL: String? = nil,
        carabinerFrontImageURL: String? = nil
    ) {
        self.keyringDataList = keyringDataList
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.customBackgroundColor = backgroundColor
        self.backgroundImageURL = backgroundImageURL
        self.carabinerBackImageURL = carabinerBackImageURL
        self.carabinerFrontImageURL = carabinerFrontImageURL

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
        let sceneStartTime = Date()
        backgroundColor = customBackgroundColor
        // 물리 시뮬레이션을 처음에는 비활성화
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)  // 중력 0으로 설정

        print("🎬 [MultiKeyringScene] didMove 시작 (시간: 0.000초)")

        // 모든 이미지를 동시에 로드 시작
        Task {
            let imageLoadStart = Date()
            print("🖼️ [MultiKeyringScene] 이미지 로드 시작 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")

            async let backgroundTask: Void = {
                if let backgroundURL = backgroundImageURL {
                    await setupBackgroundImageAsync(url: backgroundURL, sceneStartTime: sceneStartTime)
                }
            }()

            async let carabinerBackTask: Void = {
                if let carabinerBackURL = carabinerBackImageURL {
                    await setupCarabinerBackImageAsync(url: carabinerBackURL, sceneStartTime: sceneStartTime)
                }
            }()

            async let carabinerFrontTask: Void = {
                if let carabinerFrontURL = carabinerFrontImageURL {
                    await setupCarabinerFrontImageAsync(url: carabinerFrontURL, sceneStartTime: sceneStartTime)
                }
            }()

            // 모든 이미지 로드 병렬 실행
            await backgroundTask
            await carabinerBackTask
            await carabinerFrontTask

            let imageLoadElapsed = Date().timeIntervalSince(imageLoadStart)
            print("✅ [MultiKeyringScene] 모든 이미지 로드 완료 - 소요시간: \(String(format: "%.3f", imageLoadElapsed))초 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")

            // 키링 설정
            await MainActor.run {
                print("🔧 [MultiKeyringScene] 키링 설정 시작 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
                self.setupKeyrings(sceneStartTime: sceneStartTime)
            }
        }
    }

    // MARK: - Background & Carabiner Setup

    /// 배경 이미지 설정 (async)
    private func setupBackgroundImageAsync(url: String, sceneStartTime: Date) async {
        let start = Date()
        print("  📥 [Background] 다운로드 시작...")

        guard let image = try? await StorageManager.shared.getImage(path: url) else {
            print("  ❌ [Background] 로드 실패 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
            return
        }

        let downloadElapsed = Date().timeIntervalSince(start)
        print("  📦 [Background] 다운로드 완료 - \(String(format: "%.3f", downloadElapsed))초")

        await MainActor.run {
            let texture = SKTexture(image: image)
            let backgroundNode = SKSpriteNode(texture: texture)

            backgroundNode.size = self.size
            backgroundNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            backgroundNode.zPosition = -1000

            self.addChild(backgroundNode)
            let totalElapsed = Date().timeIntervalSince(start)
            print("  ✅ [Background] 씬 추가 완료 - 총 \(String(format: "%.3f", totalElapsed))초 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
        }
    }

    /// 카라비너 뒷면 이미지 설정 (async)
    private func setupCarabinerBackImageAsync(url: String, sceneStartTime: Date) async {
        let start = Date()
        print("  📥 [CarabinerBack] 다운로드 시작...")

        guard let image = try? await StorageManager.shared.getImage(path: url) else {
            print("  ❌ [CarabinerBack] 로드 실패 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
            return
        }

        let downloadElapsed = Date().timeIntervalSince(start)
        print("  📦 [CarabinerBack] 다운로드 완료 - \(String(format: "%.3f", downloadElapsed))초")

        await MainActor.run {
            let texture = SKTexture(image: image)
            let carabinerNode = SKSpriteNode(texture: texture)

            let imageAspectRatio = image.size.height / image.size.width
            let nodeWidth = self.size.width
            let nodeHeight = nodeWidth * imageAspectRatio

            carabinerNode.size = CGSize(width: nodeWidth, height: nodeHeight)
            carabinerNode.position = CGPoint(
                x: self.size.width / 2,
                y: self.size.height - nodeHeight / 2 - 60
            )
            carabinerNode.zPosition = -900

            self.addChild(carabinerNode)
            let totalElapsed = Date().timeIntervalSince(start)
            print("  ✅ [CarabinerBack] 씬 추가 완료 - 총 \(String(format: "%.3f", totalElapsed))초 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
        }
    }

    /// 카라비너 앞면 이미지 설정 (async)
    private func setupCarabinerFrontImageAsync(url: String, sceneStartTime: Date) async {
        let start = Date()
        print("  📥 [CarabinerFront] 다운로드 시작...")

        guard let image = try? await StorageManager.shared.getImage(path: url) else {
            print("  ❌ [CarabinerFront] 로드 실패 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
            return
        }

        let downloadElapsed = Date().timeIntervalSince(start)
        print("  📦 [CarabinerFront] 다운로드 완료 - \(String(format: "%.3f", downloadElapsed))초")

        await MainActor.run {
            let texture = SKTexture(image: image)
            let carabinerNode = SKSpriteNode(texture: texture)

            let imageAspectRatio = image.size.height / image.size.width
            let nodeWidth = self.size.width
            let nodeHeight = nodeWidth * imageAspectRatio

            carabinerNode.size = CGSize(width: nodeWidth, height: nodeHeight)
            carabinerNode.position = CGPoint(
                x: self.size.width / 2,
                y: self.size.height - nodeHeight / 2 - 60
            )
            carabinerNode.zPosition = 10000

            self.addChild(carabinerNode)
            let totalElapsed = Date().timeIntervalSince(start)
            print("  ✅ [CarabinerFront] 씬 추가 완료 - 총 \(String(format: "%.3f", totalElapsed))초 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
        }
    }

    // MARK: - Setup

    /// 모든 키링 설정
    private func setupKeyrings(sceneStartTime: Date) {
        let startTime = Date()

        // 모든 키링이 동기적으로 생성될 때까지 카운터 사용
        let totalKeyrings = keyringDataList.count

        guard totalKeyrings > 0 else {
            print("⚠️ [MultiKeyringScene] 키링이 없음")
            enablePhysics(sceneStartTime: sceneStartTime)
            return
        }

        var completedKeyrings = 0

        for (order, data) in keyringDataList.enumerated() {
            print("  🔨 [Keyring \(order + 1)/\(totalKeyrings)] 생성 시작...")
            setupSingleKeyring(data: data, order: order, sceneStartTime: sceneStartTime) { [weak self] in
                completedKeyrings += 1
                print("  ✓ [Keyring \(completedKeyrings)/\(totalKeyrings)] 완성 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")

                if completedKeyrings == totalKeyrings {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("✅ [모든 키링 완성] 소요시간: \(String(format: "%.3f", elapsed))초 (총 경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")
                    // 모든 키링 완성 후 물리 활성화
                    self?.enablePhysics(sceneStartTime: sceneStartTime)
                }
            }
        }
    }

    /// 단일 키링 설정
    private func setupSingleKeyring(data: KeyringData, order: Int, sceneStartTime: Date, completion: @escaping () -> Void) {
        let keyringStart = Date()

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

        guard let carabinerType = currentCarabinerType else {
            completion()
            return
        }

        print("    🔹 [Keyring \(data.index)] Ring 생성 시작...")
        let ringStart = Date()

        BundleRingComponent.createCarabinerRingNode(
            carabinerType: carabinerType,
            ringType: currentRingType
        ) { [weak self] createdRing in
            guard let self = self, let ring = createdRing else {
                completion()
                return
            }
            ring.zPosition = baseZPosition  // Ring이 가장 뒤

            let ringFrame = ring.calculateAccumulatedFrame()
            let ringRadius = ringFrame.height / 2

            // Ring 위치: Ring의 상단이 정확히 + 버튼 위치에 오도록 설정
            let ringCenterX = spriteKitPosition.x
            // 미세 조정: 필요시 오프셋 추가
            let ringCenterY = spriteKitPosition.y - ringRadius  // +2pt 오프셋으로 조정
            ring.position = CGPoint(x: ringCenterX, y: ringCenterY)

            // Ring이 처음에는 물리 시뮬레이션 비활성화
            ring.physicsBody?.isDynamic = false
            ring.physicsBody?.categoryBitMask = categoryBitMask
            ring.physicsBody?.collisionBitMask = collisionBitMask
            ring.physicsBody?.contactTestBitMask = 0
            self.addChild(ring)

            // Ring 노드 저장
            self.ringNodes[data.index] = ring
            self.keyringNodes[data.index] = ring

            let ringElapsed = Date().timeIntervalSince(ringStart)
            print("    ✓ [Keyring \(data.index)] Ring 완료 - \(String(format: "%.3f", ringElapsed))초")

            // 2. Chain 생성
            self.setupChain(
                ring: ring,
                centerX: spriteKitPosition.x,
                bodyImageURL: data.bodyImageURL,
                index: data.index,
                baseZPosition: baseZPosition,
                keyringStart: keyringStart,
                sceneStartTime: sceneStartTime,
                completion: completion
            )
        }
    }

    /// Chain 생성
    private func setupChain(
        ring: SKSpriteNode,
        centerX: CGFloat,
        bodyImageURL: String,
        index: Int,
        baseZPosition: CGFloat,
        keyringStart: Date,
        sceneStartTime: Date,
        completion: @escaping () -> Void
    ) {
        print("    🔹 [Keyring \(index)] Chain 생성 시작...")
        let chainStart = Date()
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY + 0.5
        let chainSpacing: CGFloat = 20

        KeyringChainComponent.createLinks(
            from: currentChainType,
            count: 6,
            startPosition: CGPoint(x: centerX, y: chainStartY),
            spacing: chainSpacing,
            carabinerType: currentCarabinerType,
            baseZPosition: baseZPosition
        ) { [weak self] chains in
            guard let self = self else { return }

            // 각 체인에 고유한 물리 마스크 적용
            let categoryBitMask: UInt32 = UInt32(1 << index)
            let collisionBitMask: UInt32 = categoryBitMask

            for (chainIndex, chain) in chains.enumerated() {
                // zPosition은 KeyringChainComponent에서 이미 설정됨
                // 체인도 처음에는 물리 비활성화
                chain.physicsBody?.isDynamic = false
                chain.physicsBody?.categoryBitMask = categoryBitMask
                chain.physicsBody?.collisionBitMask = collisionBitMask
                chain.physicsBody?.contactTestBitMask = 0
                self.addChild(chain)
            }

            // Chain 노드 저장
            self.chainNodesByKeyring[index] = chains

            let chainElapsed = Date().timeIntervalSince(chainStart)
            print("    ✓ [Keyring \(index)] Chain 완료 - \(String(format: "%.3f", chainElapsed))초")

            // 3. Body 생성
            self.setupBody(
                ring: ring,
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                bodyImageURL: bodyImageURL,
                index: index,
                baseZPosition: baseZPosition,
                keyringStart: keyringStart,
                sceneStartTime: sceneStartTime,
                completion: completion
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
        baseZPosition: CGFloat,
        keyringStart: Date,
        sceneStartTime: Date,
        completion: @escaping () -> Void
    ) {
        print("    🔹 [Keyring \(index)] Body 이미지 로드 시작...")
        let bodyStart = Date()

        KeyringBodyComponent.createNode(from: bodyImageURL) { [weak self] body in
            guard let self = self, let body = body else {
                completion()  // body 생성 실패 시에도 completion 호출
                return
            }

            let bodyElapsed = Date().timeIntervalSince(bodyStart)
            print("    ✓ [Keyring \(index)] Body 이미지 로드 완료 - \(String(format: "%.3f", bodyElapsed))초")

            self.positionAndConnectBody(
                body: body,
                ring: ring,
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                index: index,
                baseZPosition: baseZPosition,
                keyringStart: keyringStart,
                sceneStartTime: sceneStartTime,
                completion: completion
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
        baseZPosition: CGFloat,
        keyringStart: Date,
        sceneStartTime: Date,
        completion: @escaping () -> Void
    ) {
        print("    🔹 [Keyring \(index)] Body 위치 설정 및 조인트 연결 시작...")
        let connectStart = Date()
        let bodyFrame = body.calculateAccumulatedFrame()
        let bodyHalfHeight = bodyFrame.height / 2

        let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
        let lastLinkHeight: CGFloat = chains.last.map { $0.calculateAccumulatedFrame().height } ?? chainSpacing
        let lastChainBottomY = lastChainY - lastLinkHeight / 2

        let connectGap = 35.0
        let bodyCenterY = lastChainBottomY - bodyHalfHeight + connectGap

        body.position = CGPoint(x: centerX, y: bodyCenterY)
        body.zPosition = baseZPosition + 1  // Body는 Ring 바로 위

        // Body에 고유한 물리 마스크 적용
        let categoryBitMask: UInt32 = UInt32(1 << index)
        let collisionBitMask: UInt32 = categoryBitMask
        // Body도 처음에는 물리 비활성화
        body.physicsBody?.isDynamic = false
        body.physicsBody?.categoryBitMask = categoryBitMask
        body.physicsBody?.collisionBitMask = collisionBitMask
        body.physicsBody?.contactTestBitMask = 0

        addChild(body)

        // Body 노드 저장
        bodyNodes[index] = body

        // 조인트 연결
        connectComponents(ring: ring, chains: chains, body: body)

        let connectElapsed = Date().timeIntervalSince(connectStart)
        print("    ✓ [Keyring \(index)] 조인트 연결 완료 - \(String(format: "%.3f", connectElapsed))초")

        let totalKeyringElapsed = Date().timeIntervalSince(keyringStart)
        print("    ✅ [Keyring \(index)] 전체 완성 - 총 소요시간: \(String(format: "%.3f", totalKeyringElapsed))초")

        // 키링 완성 완료
        completion()
    }

    /// 키링 구성 요소들을 Joint로 연결
    private func connectComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        var previousNode: SKNode = ring

        // Ring과 첫 번째 Chain 연결
        if let firstChain = chains.first {
            let anchorY = previousNode.position.y

            // physicsBody 존재 확인 (안전한 코딩)
            guard let ringPhysics = ring.physicsBody,
                  let chainPhysics = firstChain.physicsBody else {
                print("[MultiKeyringScene] Warning: Missing physics body for joint connection")
                return
            }

            // Plain 타입일 때는 첫 번째 체인을 고정하는 조인트 설정
            if let carabinerType = currentCarabinerType, carabinerType == .plain {
                // Ring의 하단에서 체인과 연결 (Ring 상단은 anchor로 고정됨)
                let ringFrame = ring.calculateAccumulatedFrame()
                let connectionPoint = CGPoint(
                    x: ring.position.x,
                    y: ring.position.y - ringFrame.height/2  // Ring의 하단
                )

                let joint = SKPhysicsJointPin.joint(
                    withBodyA: ringPhysics,
                    bodyB: chainPhysics,
                    anchor: connectionPoint
                )
                joint.shouldEnableLimits = false
                joint.frictionTorque = 5.0  // 첫 번째 체인을 거의 고정시키는 높은 마찰
                physicsWorld.add(joint)

                print("[MultiKeyringScene] Plain: First chain fixed with high friction")
            } else {
                // Hamburger 타입은 기존 핀 조인트 유지
                let joint = SKPhysicsJointPin.joint(
                    withBodyA: ringPhysics,
                    bodyB: chainPhysics,
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
                    withBodyA: ringPhysics,
                    bodyB: chainPhysics,
                    anchorA: CGPoint.zero,
                    anchorB: CGPoint.zero
                )
                limitJoint.maxLength = distance * 1.05
                physicsWorld.add(limitJoint)
            }

            firstChain.physicsBody?.linearDamping = 2.0  // 첫 번째 체인을 거의 고정
            firstChain.physicsBody?.angularDamping = 3.0

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

        // Plain 타입에서는 Ring을 dynamic으로 유지하되 위치 제한 (anchor에 의해 제어됨)
        if let carabinerType = currentCarabinerType, carabinerType == .plain {
            // Ring은 dynamic 상태 유지하되 anchor가 위치 제어
            print("[MultiKeyringScene] Plain: Ring kept dynamic for natural swing with anchor")
        } else {
            // Hamburger 타입에서만 Ring을 static으로 설정
            ring.physicsBody?.isDynamic = false
            print("[MultiKeyringScene] Hamburger: Ring kept static after joint connections")
        }
    }

    /// 모든 키링이 완성된 후 물리 시뮬레이션 활성화
    private func enablePhysics(sceneStartTime: Date) {
        let physicsStart = Date()
        print("⚡️ [MultiKeyringScene] 물리 시뮬레이션 활성화 시작 (경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")

        // 중력 활성화 (모든 타입에서)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        // 카라비너 타입별 Ring 물리 설정
        for (index, ring) in ringNodes {
            if let carabinerType = currentCarabinerType, carabinerType == .plain {
                // Plain 타입: Ring 완전히 고정
                ring.physicsBody?.isDynamic = false
                print("[MultiKeyringScene] Plain: Ring completely fixed (static)")
            } else {
                // Hamburger 타입: Ring은 완전히 고정
                ring.physicsBody?.isDynamic = false
                print("[MultiKeyringScene] Hamburger: Ring kept static")
            }
        }

        // 카라비너 타입별 체인 물리 활성화
        for (_, chains) in chainNodesByKeyring {
            if let carabinerType = currentCarabinerType, carabinerType == .plain {
                // Plain 타입: 첫 번째 체인 완전 고정, 나머지는 자유롭게 움직임
                for (index, chain) in chains.enumerated() {
                    if index == 0 {
                        // 첫 번째 체인: 완전히 고정 (물리 비활성화)
                        chain.physicsBody?.isDynamic = false
                    } else {
                        // 나머지 체인들: 자유롭게 움직임
                        chain.physicsBody?.isDynamic = true
                        chain.physicsBody?.linearDamping = 0.5  // 매우 낮은 감쇠로 자유로운 움직임
                        chain.physicsBody?.angularDamping = 0.5
                    }
                }
            } else {
                // Hamburger 타입: 모든 체인 활성화
                for chain in chains {
                    chain.physicsBody?.isDynamic = true
                    chain.physicsBody?.linearDamping = 0.5
                    chain.physicsBody?.angularDamping = 0.5
                }
            }
        }

        // 모든 바디의 물리 활성화
        for (_, body) in bodyNodes {
            body.physicsBody?.isDynamic = true
            body.physicsBody?.linearDamping = 0.5
            body.physicsBody?.angularDamping = 0.5
        }

        let physicsElapsed = Date().timeIntervalSince(physicsStart)
        print("✅ [MultiKeyringScene] 물리 시뮬레이션 활성화 완료 - 소요시간: \(String(format: "%.3f", physicsElapsed))초 (총 경과: \(String(format: "%.3f", Date().timeIntervalSince(sceneStartTime)))초)")

        onAllKeyringsReady?()
    }

    // MARK: - Helper Methods

    /// 비율 좌표를 SpriteKit 절대 좌표로 변환
    /// point.x, point.y는 화면 크기의 배수 (0.0 ~ 1.0 범위)
    private func convertToSpriteKitCoordinates(_ point: CGPoint) -> CGPoint {
        let absoluteX = point.x * size.width
        let absoluteY = (1.0 - point.y) * size.height  // SwiftUI는 위에서 아래로, SpriteKit은 아래에서 위로
        return CGPoint(x: absoluteX, y: absoluteY)
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

    /// 사운드 효과 재생
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

                // Plain 타입일 때는 Ring과 체인이 모두 찰랑거림
                if let carabinerType = currentCarabinerType, carabinerType == .plain {
                    // Ring도 체인처럼 부드럽게 힘 적용
                    if let ring = ringNodes[index] {
                        ring.physicsBody?.applyImpulse(CGVector(dx: force.dx * 0.4, dy: force.dy * 0.4))
                    }

                    // 모든 체인에도 힘 적용
                    for chain in chains {
                        chain.physicsBody?.applyImpulse(force)
                    }
                } else {
                    // Hamburger 타입: 모든 체인에 힘 적용
                    for chain in chains {
                        chain.physicsBody?.applyImpulse(force)
                    }
                }

                // Body에도 힘 적용
                body.physicsBody?.applyImpulse(force)
            }
        }
    }
}
