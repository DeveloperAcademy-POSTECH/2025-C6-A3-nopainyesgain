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
        let position: CGPoint       // 절대 좌표 (SwiftUI 좌표계)
        let bodyImageURL: String
        let templateId: String?     // 템플릿 ID (옵션)
        let soundId: String         // 사운드 ID
        let customSoundURL: URL?    // 커스텀 녹음 파일 URL
        let particleId: String      // 파티클 ID
        let hookOffsetY: CGFloat?   // 바디 연결 지점 Y 오프셋 (nil이면 0.0 사용)
        let chainLength: Int        // 체인 길이 (기본값 5)

        init(index: Int, position: CGPoint, bodyImageURL: String, templateId: String? = nil, soundId: String, customSoundURL: URL? = nil, particleId: String, hookOffsetY: CGFloat? = nil, chainLength: Int = 5) {
            self.index = index
            self.position = position
            self.bodyImageURL = bodyImageURL
            self.templateId = templateId
            self.soundId = soundId
            self.customSoundURL = customSoundURL
            self.particleId = particleId
            self.hookOffsetY = hookOffsetY
            self.chainLength = chainLength
        }
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

    // MARK: - 예약된 작업 관리
    private var readyCallbackWorkItem: DispatchWorkItem?

    // MARK: - 키링 로드 완료 추적
    private var totalKeyringsToLoad = 0  // 로드해야 할 총 키링 수
    private var loadedKeyringsCount = 0  // 완료(성공/실패)된 키링 수
    private var loadedKeyringsSuccessCount = 0  // 성공적으로 로드된 키링 수
    private var isPhysicsEnabled = false  // 물리 엔진 활성화 여부

    // MARK: - 카라비너 로드 상태
    private var carabinerBackReady = false
    private var carabinerFrontReady = false
    private var didStartKeyringSetup = false

    // MARK: - 씬 정리 상태
    private var isCleaningUp = false

    // MARK: - 선택된 타입들
    var currentCarabinerType: CarabinerType?
    var currentRingType: RingType = .basic
    var currentChainType: ChainType = .basic

    // MARK: - 배경색 및 이미지 설정
    var customBackgroundColor: UIColor = .clear
    var backgroundImageURL: String?  // 배경 이미지 URL
    var carabinerBackImageURL: String?  // 카라비너 뒷면 이미지 (hamburger 타입)
    var carabinerFrontImageURL: String?  // 카라비너 앞면 이미지 (hamburger 타입)

    // MARK: - 카라비너 크기 및 위치 정보
    var carabinerX: CGFloat = 0  // 카라비너 중심 X 좌표
    var carabinerY: CGFloat = 0  // 카라비너 중심 Y 좌표
    var carabinerWidth: CGFloat = 0  // 카라비너 너비

    // MARK: - 카라비너 노드 저장
    private var carabinerBackNode: SKSpriteNode?
    private var carabinerFrontNode: SKSpriteNode?

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
        carabinerFrontImageURL: String? = nil,
        carabinerX: CGFloat = 0,
        carabinerY: CGFloat = 0,
        carabinerWidth: CGFloat = 0
    ) {
        self.keyringDataList = keyringDataList
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.customBackgroundColor = backgroundColor
        self.backgroundImageURL = backgroundImageURL
        self.carabinerBackImageURL = carabinerBackImageURL
        self.carabinerFrontImageURL = carabinerFrontImageURL
        self.carabinerX = carabinerX
        self.carabinerY = carabinerY
        self.carabinerWidth = carabinerWidth

        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        cleanup()
    }

    /// 씬 정리 (메모리 해제 전 호출)
    func cleanup() {
        guard !isCleaningUp else { return }
        isCleaningUp = true
        

        // 예약된 콜백 취소
        readyCallbackWorkItem?.cancel()
        readyCallbackWorkItem = nil

        // 콜백 무효화
        onAllKeyringsReady = nil
        onPlayParticleEffect = nil
        
        // 추적 변수 초기화
        totalKeyringsToLoad = 0
        loadedKeyringsCount = 0
        loadedKeyringsSuccessCount = 0
        isPhysicsEnabled = false
        carabinerBackReady = false
        carabinerFrontReady = false
        didStartKeyringSetup = false

        // 모든 물리 조인트 제거
        physicsWorld.removeAllJoints()

        // 모든 액션 제거
        removeAllActions()

        // 모든 자식 노드 제거
        removeAllChildren()
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = customBackgroundColor
        // 물리 시뮬레이션을 처음에는 비활성화
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)  // 중력 0으로 설정

        // 씬 사이즈가 아직 0일 수 있으므로 한 프레임 지연
        if size.width == 0 || size.height == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.beginLoading()
            }
        } else {
            beginLoading()
        }
    }

    private func beginLoading() {
        // 카라비너 이미지와 키링들을 로드
        Task {
            async let carabinerBackTask: Void = {
                if let carabinerBackURL = await carabinerBackImageURL {
                    if carabinerBackURL != "none" {
                        await setupCarabinerBackImageAsync(url: carabinerBackURL)
                    }
                }
                await MainActor.run { self.carabinerBackReady = true }
            }()

            async let carabinerFrontTask: Void = {
                if let carabinerFrontURL = await carabinerFrontImageURL {
                    await setupCarabinerFrontImageAsync(url: carabinerFrontURL)
                }
                await MainActor.run { self.carabinerFrontReady = true }
            }()

            // 카라비너 이미지 로드 병렬 실행
            await carabinerBackTask
            await carabinerFrontTask

            // 키링 설정 (카라비너 준비 후)
            await MainActor.run {
                self.setupKeyringsIfNeeded()
            }
        }
    }

    // MARK: - Shadow Helper

    /// 노드에 수직 그림자 추가 (z축 위에서 내려오는 광원)
    /// - Parameters:
    ///   - node: 그림자를 추가할 노드
    ///   - offsetX: X축 오프셋 (기본값 8)
    ///   - offsetY: Y축 오프셋 (기본값 -8)
    ///   - blurRadius: Gaussian Blur 강도 (기본값 5.0)
    private func addShadowToNode(_ node: SKSpriteNode, offsetX: CGFloat = 8, offsetY: CGFloat = -8, blurRadius: CGFloat = 5.0) {
        // 원본 노드를 복제해서 그림자로 사용
        guard let shadowNode = node.copy() as? SKSpriteNode else { return }

        // 그림자 설정 (살짝 더 진하게)
        shadowNode.alpha = 0.25
        shadowNode.color = .black
        shadowNode.colorBlendFactor = 1.0

        // z축에서 수직으로 떨어지는 그림자 (약간 아래로만 이동)
        shadowNode.position = CGPoint(x: offsetX, y: offsetY)
        shadowNode.zPosition = 0  // effectNode 내에서 기본 위치

        // 물리 바디 제거 (충돌 방지)
        shadowNode.physicsBody = nil

        // Blur 효과를 위한 SKEffectNode
        let effectNode = SKEffectNode()
        effectNode.shouldRasterize = true
        effectNode.shouldEnableEffects = true

        // 원본 노드 바로 뒤에 위치 (레이어 순서 유지)
        // 부모 노드의 zPosition - 0.5로 설정하여 다른 노드들과의 순서도 고려
        effectNode.zPosition = -0.5

        // Gaussian Blur 필터
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)
            effectNode.filter = blurFilter
        }

        effectNode.addChild(shadowNode)
        node.addChild(effectNode)
    }

    // MARK: - Carabiner Setup

    /// 카라비너 뒷면 이미지 설정 (async)
    private func setupCarabinerBackImageAsync(url: String) async {
        guard let image = try? await StorageManager.shared.getImage(path: url) else {
            return
        }

        await MainActor.run {
            let texture = SKTexture(image: image)
            let carabinerNode = SKSpriteNode(texture: texture)

            // 카라비너 크기 계산: carabinerWidth를 기준으로 비율 유지
            let imageAspectRatio = image.size.height / image.size.width
            let nodeWidth = self.carabinerWidth
            let nodeHeight = nodeWidth * imageAspectRatio

            carabinerNode.size = CGSize(width: nodeWidth, height: nodeHeight)

            // 카라비너 위치 계산: 왼쪽 상단 기준 -> 중심 기준으로 변환
            // SwiftUI 좌표(왼쪽 위 기준) -> SpriteKit 좌표(왼쪽 아래 기준)
            let centerX = self.carabinerX + nodeWidth / 2
            let centerY = self.carabinerY + nodeHeight / 2
            let spriteKitY = self.size.height - centerY

            carabinerNode.position = CGPoint(x: centerX, y: spriteKitY)
            carabinerNode.zPosition = -900

            self.addChild(carabinerNode)

            // 수직 그림자 추가
            self.addShadowToNode(carabinerNode, offsetX: 2, offsetY: -3, blurRadius: 1.0)

            // 카라비너 뒷면 노드 저장
            self.carabinerBackNode = carabinerNode
        }
    }

    /// 카라비너 앞면 이미지 설정 (async)
    private func setupCarabinerFrontImageAsync(url: String) async {
        guard let image = try? await StorageManager.shared.getImage(path: url) else {
            return
        }

        await MainActor.run {
            let texture = SKTexture(image: image)
            let carabinerNode = SKSpriteNode(texture: texture)

            // 카라비너 크기 계산: carabinerWidth를 기준으로 비율 유지
            let imageAspectRatio = image.size.height / image.size.width
            let nodeWidth = self.carabinerWidth
            let nodeHeight = nodeWidth * imageAspectRatio

            carabinerNode.size = CGSize(width: nodeWidth, height: nodeHeight)

            // 카라비너 위치 계산: 왼쪽 상단 기준 -> 중심 기준으로 변환
            // SwiftUI 좌표(왼쪽 위 기준) -> SpriteKit 좌표(왼쪽 아래 기준)
            let centerX = self.carabinerX + nodeWidth / 2
            let centerY = self.carabinerY + nodeHeight / 2
            let spriteKitY = self.size.height - centerY

            carabinerNode.position = CGPoint(x: centerX, y: spriteKitY)
            carabinerNode.zPosition = -800  // 카라비너 뒷면(-900)과 키링들(0~) 사이

            self.addChild(carabinerNode)

            // 카라비너 앞면 노드 저장
            self.carabinerFrontNode = carabinerNode
        }
    }

    // MARK: - Setup

    private func setupKeyringsIfNeeded() {
        guard !didStartKeyringSetup else { return }
        // 카라비너가 준비된 뒤에만 시작
        guard carabinerBackReady && carabinerFrontReady else { return }
        didStartKeyringSetup = true
        setupKeyrings()
    }

    /// 모든 키링 설정
    private func setupKeyrings() {
        // 모든 키링이 동기적으로 생성될 때까지 카운터 사용
        totalKeyringsToLoad = keyringDataList.count
        loadedKeyringsCount = 0
        loadedKeyringsSuccessCount = 0

        guard totalKeyringsToLoad > 0 else {
            // 키링이 없어도 물리 활성화 후 준비 완료 콜백 호출
            enablePhysics()
            scheduleReadyCallbackIfAllDone()
            return
        }

        for (order, data) in keyringDataList.enumerated() {
            setupSingleKeyring(data: data, order: order) { [weak self] success in
                guard let self = self else { return }
                
                // 성공 여부와 관계없이 완료된 키링 수 증가
                self.loadedKeyringsCount += 1
                if success { self.loadedKeyringsSuccessCount += 1 }
                
                // 모든 키링 로드 완료 체크
                if self.loadedKeyringsCount == self.totalKeyringsToLoad {
                    // 모든 키링 완성 후 물리 활성화
                    self.enablePhysics()
                    // 성공한 경우에만 ready 콜백 예약
                    self.scheduleReadyCallbackIfAllDone()
                }
            }
        }
    }

    /// 단일 키링 설정 (이미지 먼저 다운로드하고 조립)
    private func setupSingleKeyring(data: KeyringData, order: Int, completion: @escaping (Bool) -> Void) {
        // 사운드 정보 저장
        soundIdsByKeyring[data.index] = data.soundId
        if let customURL = data.customSoundURL {
            customSoundURLsByKeyring[data.index] = customURL
        }
        
        // 파티클 정보 저장
        particleIdsByKeyring[data.index] = data.particleId

        // 절대 좌표를 SpriteKit 좌표로 변환 (Y축만 반전)
        let spriteKitPosition = CGPoint(
            x: data.position.x,
            y: size.height - data.position.y
        )


        // 각 키링 그룹에 고유한 categoryBitMask 설정 (충돌 방지)
        let categoryBitMask: UInt32 = UInt32(1 << data.index)
        let collisionBitMask: UInt32 = categoryBitMask  // 자기 그룹 내에서만 충돌

        // zPosition 계산: 생성 순서대로 레이어링 (나중에 생성된 것이 위에)
        let baseZPosition = CGFloat(order * 10)

        guard let carabinerType = currentCarabinerType else {
            completion(false)
            return
        }

        // 모든 이미지를 다운로드한 후에 조립
        downloadImagesForKeyring(
            bodyImageURL: data.bodyImageURL,
            templateId: data.templateId,
            chainLength: data.chainLength
        ) { [weak self] result in
            guard let self = self else {
                completion(false)
                return
            }

            switch result {
            case .success(let images):
                // 이미지 다운로드 완료 후 조립 시작
                self.assembleKeyring(
                    data: data,
                    images: images,
                    spriteKitPosition: spriteKitPosition,
                    baseZPosition: baseZPosition,
                    categoryBitMask: categoryBitMask,
                    collisionBitMask: collisionBitMask,
                    carabinerType: carabinerType,
                    completion: completion
                )

            case .failure:
                completion(false)
            }
        }
    }

    // MARK: - 키링용 이미지 다운로드
    struct KeyringDownloadImages {
        let ring: UIImage
        let chains: [Int: UIImage]
        let chainLinks: [ChainType.ChainLink]
        let body: UIImage?
    }

    private func downloadImagesForKeyring(
        bodyImageURL: String,
        templateId: String?,
        chainLength: Int,
        completion: @escaping (Result<KeyringDownloadImages, Error>) -> Void
    ) {
        Task {
            do {
                // 1. Ring 이미지 다운로드
                let ringImage = try await StorageManager.shared.getImage(
                    path: (currentCarabinerType == .plain ? currentRingType.sideImageURL : currentRingType.imageURL)
                )

                // 2. Chain 링크 생성 및 이미지 다운로드
                let chainLinks = currentChainType.createChainLinks(length: chainLength)
                let chainImages = try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
                    var images: [Int: UIImage] = [:]

                    for (index, link) in chainLinks.enumerated() {
                        group.addTask {
                            let image = try await StorageManager.shared.getImage(path: link.imageURL)
                            return (index, image)
                        }
                    }

                    for try await (index, image) in group {
                        images[index] = image
                    }

                    return images
                }

                // 3. Body 이미지 다운로드 (있으면)
                var bodyImage: UIImage?
                if !bodyImageURL.isEmpty {
                    let downloaded = try await StorageManager.shared.getImage(path: bodyImageURL)
                    bodyImage = downloaded.fixedOrientation()
                }

                await MainActor.run {
                    let images = KeyringDownloadImages(
                        ring: ringImage,
                        chains: chainImages,
                        chainLinks: chainLinks,
                        body: bodyImage
                    )
                    completion(.success(images))
                }

            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - 다운로드된 이미지로 키링 조립
    private func assembleKeyring(
        data: KeyringData,
        images: KeyringDownloadImages,
        spriteKitPosition: CGPoint,
        baseZPosition: CGFloat,
        categoryBitMask: UInt32,
        collisionBitMask: UInt32,
        carabinerType: CarabinerType,
        completion: @escaping (Bool) -> Void
    ) {
        guard !isCleaningUp else {
            completion(false)
            return
        }

        // 1. Ring 생성
        let ring = (
            carabinerType == .plain ? BundleRingComponent.createPlainRingNode(
                image: images.ring,
                ringType: currentRingType
            ) : BundleRingComponent.createHamburgerRingNode(image: images.ring, ringType: currentRingType)
        )
        
        // 햄버거 타입일 때 Ring을 카라비너 뒷면과 앞면 사이에 배치
        if carabinerType == .hamburger {
            ring.zPosition = -850  // 카라비너 뒷면(-900)과 앞면(-800) 사이
        } else {
            ring.zPosition = baseZPosition
        }

        let ringFrame = ring.calculateAccumulatedFrame()
        let ringRadius = ringFrame.height / 2
        
        // Ring 위치: Ring의 상단이 정확히 + 버튼 위치에 오도록 설정
        let ringCenterX = spriteKitPosition.x
        // 미세 조정: 필요시 오프셋 추가
        let ringCenterY = spriteKitPosition.y - ringRadius  // +2pt 오프셋으로 조정
        ring.position = CGPoint(x: ringCenterX, y: ringCenterY)
        
        //Ring이 처음에는 물리 시뮬레이션 비활성화
        ring.physicsBody?.isDynamic = false
        ring.physicsBody?.categoryBitMask = categoryBitMask
        ring.physicsBody?.collisionBitMask = collisionBitMask
        ring.physicsBody?.contactTestBitMask = 0
        
        addChild(ring)
        
        // 수직 그림자 추가
        addShadowToNode(ring, offsetX: 4, offsetY: -8)
        
        // Ring 노드 저장
        ringNodes[data.index] = ring
        keyringNodes[data.index] = ring

        // 2. Chain 생성
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY + 2
        let chainSpacing: CGFloat = 22

        let chainCount: Int = (currentCarabinerType == .plain ? max(data.chainLength - 1, 1) : data.chainLength)

        KeyringChainComponent.createLinks(
            from: currentChainType,
            count: chainCount,
            startPosition: CGPoint(x: ringCenterX, y: chainStartY),
            spacing: chainSpacing,
            carabinerType: currentCarabinerType,
            baseZPosition: baseZPosition
        ) { [weak self] createdChains in
            guard let self = self, !self.isCleaningUp else { return }

            var chains: [SKSpriteNode] = []

            for (_, chainNode) in createdChains.enumerated() {
                // assembleKeyring 기존 초기 물리 설정 유지
                chainNode.physicsBody?.isDynamic = false
                chainNode.physicsBody?.categoryBitMask = categoryBitMask
                chainNode.physicsBody?.collisionBitMask = collisionBitMask
                chainNode.physicsBody?.contactTestBitMask = 0

                self.addChild(chainNode)
                self.addShadowToNode(chainNode, offsetX: 4, offsetY: -8)
                chains.append(chainNode)
            }
            self.chainNodesByKeyring[data.index] = chains

            // 3. Body 생성
            let body: SKNode
            if let bodyImage = images.body {
                body = self.createBodyNode(image: bodyImage)
            } else {
                body = self.createBasicBodyNode()
            }

            // Body 위치 계산
            let bodyFrame = body.calculateAccumulatedFrame()
            let bodyHalfHeight = bodyFrame.height / 2

            let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
            let lastChainBottomY = lastChainY - 15

            let hookOffsetYRatio = data.hookOffsetY ?? 0.0
            let actualHookOffsetY = hookOffsetYRatio * bodyFrame.height

            let bodyCenterY = lastChainBottomY - bodyHalfHeight + actualHookOffsetY + 4

            body.position = CGPoint(x: spriteKitPosition.x, y: bodyCenterY)
            body.zPosition = baseZPosition - 2
            body.physicsBody?.isDynamic = false
            body.physicsBody?.categoryBitMask = categoryBitMask
            body.physicsBody?.collisionBitMask = collisionBitMask
            body.physicsBody?.contactTestBitMask = 0

            self.addChild(body)

            if let spriteBody = body as? SKSpriteNode {
                self.addShadowToNode(spriteBody, offsetX: 8, offsetY: -8)
            }

            self.bodyNodes[data.index] = body

            // 4. 조인트 연결
            self.connectComponents(ring: ring, chains: chains, body: body)

            // 키링 완성 완료 - 성공
            completion(true)
        }
    }

    private func createBodyNode(image: UIImage) -> SKSpriteNode {
        let maxSize: CGFloat = 200
        let originalSize = image.size
        var displaySize = originalSize

        let maxDimension = max(originalSize.width, originalSize.height)
        if maxDimension > maxSize {
            let scale = maxSize / maxDimension
            displaySize = CGSize(
                width: originalSize.width * scale,
                height: originalSize.height * scale
            )
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let spriteNode = SKSpriteNode(texture: texture, size: displaySize)

        let physicsBody = SKPhysicsBody(rectangleOf: displaySize)
        physicsBody.mass = 2.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        spriteNode.physicsBody = physicsBody

        return spriteNode
    }

    private func createBasicBodyNode() -> SKShapeNode {
        let radius: CGFloat = 40
        let path = CGPath(
            ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
            transform: nil
        )

        let node = SKShapeNode(path: path)
        node.fillColor = .white
        node.strokeColor = UIColor(white: 0.8, alpha: 0.4)
        node.lineWidth = 1.0

        let physicsBody = SKPhysicsBody(circleOfRadius: radius - 2)
        physicsBody.mass = 2.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        node.physicsBody = physicsBody

        return node
    }

    /// 키링 구성 요소들을 Joint로 연결
    private func connectComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        // 씬이 정리 중이면 중단
        guard !isCleaningUp else { return }
        
        // Physics 카테고리 정의
        let chainCategory: UInt32 = 0x1 << 0  // 1
        let bodyCategory: UInt32 = 0x1 << 1   // 2

        var previousNode: SKNode = ring

        // Ring과 첫 번째 Chain 연결
        if let firstChain = chains.first {
            let anchorY = previousNode.position.y

            // physicsBody 존재 확인 (안전한 코딩)
            guard let ringPhysics = ring.physicsBody,
                  let chainPhysics = firstChain.physicsBody else {
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
                joint.frictionTorque = 0.1
                
                guard !isCleaningUp else { return }
                physicsWorld.add(joint)
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
                
                guard !isCleaningUp else { return }
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
                
                guard !isCleaningUp else { return }
                physicsWorld.add(limitJoint)
            }

            firstChain.physicsBody?.linearDamping = 2.0  // 첫 번째 체인을 거의 고정
            firstChain.physicsBody?.angularDamping = 3.0

            // Physics 카테고리 설정 (체인끼리만 충돌)
            firstChain.physicsBody?.categoryBitMask = chainCategory
            firstChain.physicsBody?.collisionBitMask = chainCategory

            previousNode = firstChain
        }

        // Chain 링크들 연결
        for i in 1..<chains.count {
            let current = chains[i]
            
            guard let previous = previousNode.physicsBody,
                  let currentPhysics = current.physicsBody,
                  !isCleaningUp else {
                continue
            }
            
            let joint = SKPhysicsJointPin.joint(
                withBodyA: previous,
                bodyB: currentPhysics,
                anchor: CGPoint(
                    x: (previousNode.position.x + current.position.x) / 2,
                    y: (previousNode.position.y + current.position.y) / 2
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.1
            
            guard !isCleaningUp else { return }
            physicsWorld.add(joint)

            let distance = hypot(
                current.position.x - previousNode.position.x,
                current.position.y - previousNode.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: previous,
                bodyB: currentPhysics,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = distance * 1.05
            
            guard !isCleaningUp else { return }
            physicsWorld.add(limitJoint)

            current.physicsBody?.linearDamping = 0.05
            current.physicsBody?.angularDamping = 0.05

            // Physics 카테고리 설정 (체인끼리만 충돌)
            current.physicsBody?.categoryBitMask = chainCategory
            current.physicsBody?.collisionBitMask = chainCategory
            
            previousNode = current
        }

        // 마지막 Chain과 Body 연결
        if let lastChain = chains.last {
            guard let lastChainPhysics = lastChain.physicsBody,
                  let bodyPhysics = body.physicsBody,
                  !isCleaningUp else {
                return
            }
            
            let joint = SKPhysicsJointFixed.joint(
                withBodyA: lastChainPhysics,
                bodyB: bodyPhysics,
                anchor: CGPoint(
                    x: lastChain.position.x,
                    y: lastChain.position.y
                )
            )
            
            guard !isCleaningUp else { return }
            physicsWorld.add(joint)

            let distance = hypot(
                body.position.x - lastChain.position.x,
                body.position.y - lastChain.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: lastChainPhysics,
                bodyB: bodyPhysics,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = distance * 1.05
            
            guard !isCleaningUp else { return }
            physicsWorld.add(limitJoint)

            bodyPhysics.linearDamping = 0.5
            bodyPhysics.angularDamping = 0.5

            // Physics 카테고리 설정 (Body는 아무것과도 충돌하지 않음, Joint로만 연결)
            bodyPhysics.categoryBitMask = bodyCategory
            bodyPhysics.collisionBitMask = 0  // 아무것과도 충돌하지 않음
        }

        // Plain 타입에서는 Ring을 dynamic으로 유지하되 위치 제한 (anchor에 의해 제어됨)
        if let carabinerType = currentCarabinerType, carabinerType == .plain {
            // Ring은 dynamic 상태 유지하되 anchor가 위치 제어
        } else {
            // Hamburger 타입에서만 Ring을 static으로 설정
            ring.physicsBody?.isDynamic = false
        }
    }

    /// 모든 키링이 완성된 후 물리 시뮬레이션 활성화
    private func enablePhysics() {
        // 정리 중이면 중단
        guard !isCleaningUp else {
            return
        }
        
        // 이미 물리가 활성화된 경우 중복 실행 방지
        guard !isPhysicsEnabled else {
            return
        }
        isPhysicsEnabled = true

        // 중력 활성화 (모든 타입에서)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        // 카라비너 타입별 Ring 물리 설정
        for (_, ring) in ringNodes {
            if let carabinerType = currentCarabinerType, carabinerType == .plain {
                // Plain 타입: Ring 완전히 고정
                ring.physicsBody?.isDynamic = false
            } else {
                // Hamburger 타입: Ring은 완전히 고정
                ring.physicsBody?.isDynamic = false
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
    }

    /// 모든 준비 조건이 충족되었을 때만 ready 콜백 예약
    private func scheduleReadyCallbackIfAllDone() {
        guard !isCleaningUp else { return }
        // 모든 키링이 성공적으로 로드되었을 때만
        guard loadedKeyringsSuccessCount == totalKeyringsToLoad else { return }
        // 물리 안정화를 위한 짧은 지연 (0.5초)
        readyCallbackWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isCleaningUp else { return }
            self.onAllKeyringsReady?()
        }
        readyCallbackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCleaningUp, let touch = touches.first else { return }
        let location = touch.location(in: self)

        lastTouchLocation = location
        lastTouchTime = touch.timestamp
        swipeStartLocation = location

        Haptic.impact(style: .medium)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCleaningUp, let touch = touches.first else { return }
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
        guard !isCleaningUp, let touch = touches.first else { return }
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
        guard !isCleaningUp else { return }

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
        guard !isCleaningUp else { return }

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

