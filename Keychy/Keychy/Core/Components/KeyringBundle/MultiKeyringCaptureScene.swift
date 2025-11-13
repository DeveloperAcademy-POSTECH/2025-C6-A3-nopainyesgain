//
//  MultiKeyringCaptureScene.swift
//  Keychy
//
//  캡처 전용 MultiKeyringScene (물리 법칙 없음, 정적 배치만)
//

import SpriteKit

/// 여러 키링을 정적으로 배치하는 캡처 전용 Scene (물리 법칙 없음)
class MultiKeyringCaptureScene: SKScene {

    // MARK: - Properties

    /// 키링 데이터 구조체
    struct KeyringData {
        let index: Int
        let position: CGPoint  // 절대 좌표 (SwiftUI 좌표계, 왼쪽 위 기준)
        let bodyImageURL: String
    }

    var keyringDataList: [KeyringData] = []
    var currentCarabinerType: CarabinerType?  // 카라비너 타입 추가
    var currentRingType: RingType = .basic
    var currentChainType: ChainType = .basic
    var customBackgroundColor: UIColor = .clear
    var backgroundImageURL: String?  // 배경 이미지 URL
    var carabinerBackImageURL: String?  // 카라비너 뒷면 이미지 (hamburger 타입)
    var carabinerFrontImageURL: String?  // 카라비너 앞면 이미지 (hamburger 타입)
    var onLoadingComplete: (() -> Void)?

    // MARK: - 카라비너 크기 및 위치 정보
    var carabinerX: CGFloat = 0  // 카라비너 왼쪽 상단 X 좌표
    var carabinerY: CGFloat = 0  // 카라비너 왼쪽 상단 Y 좌표
    var carabinerWidth: CGFloat = 0  // 카라비너 너비

    // 로딩 완료 추적
    private var totalKeyrings: Int = 0
    private var loadedKeyrings: Int = 0
    private var backgroundLoaded: Bool = false
    private var needsBackgroundImage: Bool = false
    private var carabinerBackLoaded: Bool = false
    private var carabinerFrontLoaded: Bool = false
    private var needsCarabinerImages: Bool = false

    // MARK: - Init

    init(
        keyringDataList: [KeyringData],
        carabinerType: CarabinerType? = nil,  // 카라비너 타입 추가
        ringType: RingType = .basic,
        chainType: ChainType = .basic,
        backgroundColor: UIColor = .clear,
        backgroundImageURL: String? = nil,  // 배경 이미지 URL (옵션)
        carabinerBackImageURL: String? = nil,  // 카라비너 뒷면 이미지 (hamburger 타입)
        carabinerFrontImageURL: String? = nil,  // 카라비너 앞면 이미지 (hamburger 타입)
        carabinerX: CGFloat = 0,
        carabinerY: CGFloat = 0,
        carabinerWidth: CGFloat = 0,
        onLoadingComplete: (() -> Void)? = nil
    ) {
        self.keyringDataList = keyringDataList
        self.currentCarabinerType = carabinerType
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.customBackgroundColor = backgroundColor
        self.backgroundImageURL = backgroundImageURL
        self.carabinerBackImageURL = carabinerBackImageURL
        self.carabinerFrontImageURL = carabinerFrontImageURL
        self.carabinerX = carabinerX
        self.carabinerY = carabinerY
        self.carabinerWidth = carabinerWidth
        self.onLoadingComplete = onLoadingComplete
        self.totalKeyrings = keyringDataList.count
        self.needsBackgroundImage = (backgroundImageURL != nil)
        self.backgroundLoaded = (backgroundImageURL == nil) // 배경이 없으면 로드 완료로 간주

        // 카라비너 이미지 로딩 추적
        self.needsCarabinerImages = (carabinerBackImageURL != nil || carabinerFrontImageURL != nil)
        self.carabinerBackLoaded = (carabinerBackImageURL == nil)
        self.carabinerFrontLoaded = (carabinerFrontImageURL == nil)

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

        // 물리 법칙 완전히 비활성화
        physicsWorld.gravity = .zero

        // 1. 배경 이미지 설정 (가장 뒤)
        if let backgroundURL = backgroundImageURL {
            setupBackgroundImage(url: backgroundURL)
        }

        // 2. 카라비너 뒷면 이미지 (배경 바로 위)
        if let carabinerBackURL = carabinerBackImageURL {
            setupCarabinerBackImage(url: carabinerBackURL)
        }

        // 3. 키링들
        setupKeyrings()

        // 4. 카라비너 앞면 이미지 (가장 위)
        if let carabinerFrontURL = carabinerFrontImageURL {
            setupCarabinerFrontImage(url: carabinerFrontURL)
        }
    }

    // MARK: - Background Setup

    /// 배경 이미지 설정
    private func setupBackgroundImage(url: String) {
        Task {
            guard let image = try? await StorageManager.shared.getImage(path: url) else {
                print("⚠️ [MultiKeyringCaptureScene] 배경 이미지 로드 실패: \(url)")
                await MainActor.run {
                    self.backgroundLoaded = true
                    self.checkLoadingComplete()
                }
                return
            }

            await MainActor.run {
                let texture = SKTexture(image: image)
                let backgroundNode = SKSpriteNode(texture: texture)

                // Scene 크기에 맞게 배경 크기 조정
                backgroundNode.size = self.size
                backgroundNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
                backgroundNode.zPosition = -1000  // 가장 뒤에 배치

                self.addChild(backgroundNode)

                // 배경 이미지 로딩 완료
                self.backgroundLoaded = true
                self.checkLoadingComplete()
            }
        }
    }

    /// 카라비너 뒷면 이미지 설정 (배경 바로 위)
    private func setupCarabinerBackImage(url: String) {
        Task {
            guard let image = try? await StorageManager.shared.getImage(path: url) else {
                print("⚠️ [MultiKeyringCaptureScene] 카라비너 뒷면 이미지 로드 실패: \(url)")
                await MainActor.run {
                    self.carabinerBackLoaded = true
                    self.checkLoadingComplete()
                }
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
                carabinerNode.zPosition = -900  // 배경(-1000) 위, 키링(0~) 아래

                self.addChild(carabinerNode)

                // 카라비너 뒷면 이미지 로딩 완료
                self.carabinerBackLoaded = true
                self.checkLoadingComplete()
            }
        }
    }

    /// 카라비너 앞면 이미지 설정 (가장 위)
    private func setupCarabinerFrontImage(url: String) {
        Task {
            guard let image = try? await StorageManager.shared.getImage(path: url) else {
                print("⚠️ [MultiKeyringCaptureScene] 카라비너 앞면 이미지 로드 실패: \(url)")
                await MainActor.run {
                    self.carabinerFrontLoaded = true
                    self.checkLoadingComplete()
                }
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
                carabinerNode.zPosition = 10000  // 가장 위에 배치

                self.addChild(carabinerNode)

                // 카라비너 앞면 이미지 로딩 완료
                self.carabinerFrontLoaded = true
                self.checkLoadingComplete()
            }
        }
    }

    // MARK: - Setup

    /// 모든 키링 정적 배치
    private func setupKeyrings() {
        for (order, data) in keyringDataList.enumerated() {
            setupSingleKeyring(data: data, order: order)
        }
    }

    /// 단일 키링 정적 배치
    private func setupSingleKeyring(data: KeyringData, order: Int) {
        // 절대 좌표를 SpriteKit 좌표로 변환 (Y축만 반전)
        let spriteKitPosition = CGPoint(
            x: data.position.x,
            y: size.height - data.position.y
        )
        let baseZPosition = CGFloat(order * 10)

        // 카라비너 타입이 있으면 BundleRingComponent 사용, 없으면 기본 Ring 사용
        guard let carabinerType = currentCarabinerType else {
            // 기존 방식 (호환성 유지)
            KeyringRingComponent.createNode(from: currentRingType) { [weak self] ring in
                guard let self = self, let ring = ring else {
                    self?.checkLoadingComplete()
                    return
                }

                ring.zPosition = baseZPosition
                let ringFrame = ring.calculateAccumulatedFrame()
                let ringRadius = ringFrame.height / 2

                ring.position = CGPoint(
                    x: spriteKitPosition.x,
                    y: spriteKitPosition.y - ringRadius
                )

                ring.physicsBody = nil
                self.addChild(ring)

                // 2. Chain 생성
                self.setupChain(
                    ring: ring,
                    centerX: spriteKitPosition.x,
                    bodyImageURL: data.bodyImageURL,
                    baseZPosition: baseZPosition
                )
            }
            return
        }

        // 1. Ring 생성 (카라비너 타입에 맞는 Ring)
        BundleRingComponent.createCarabinerRingNode(
            carabinerType: carabinerType,
            ringType: currentRingType
        ) { [weak self] ring in
            guard let self = self, let ring = ring else {
                self?.checkLoadingComplete()
                return
            }

            ring.zPosition = baseZPosition
            let ringFrame = ring.calculateAccumulatedFrame()
            let ringRadius = ringFrame.height / 2

            ring.position = CGPoint(
                x: spriteKitPosition.x,
                y: spriteKitPosition.y - ringRadius
            )

            ring.physicsBody = nil
            self.addChild(ring)

            // 2. Chain 생성
            self.setupChain(
                ring: ring,
                centerX: spriteKitPosition.x,
                bodyImageURL: data.bodyImageURL,
                baseZPosition: baseZPosition
            )
        }
    }

    /// Chain 정적 배치
    private func setupChain(
        ring: SKSpriteNode,
        centerX: CGFloat,
        bodyImageURL: String,
        baseZPosition: CGFloat
    ) {
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY + 0.5
        let chainSpacing: CGFloat = 16

        // 카라비너 타입에 따라 체인 개수 설정
        let chainCount: Int = {
            if let carabinerType = currentCarabinerType {
                return carabinerType == .plain ? 4 : 5
            }
            return 5  // 기본값
        }()

        KeyringChainComponent.createLinks(
            from: currentChainType,
            count: chainCount,
            startPosition: CGPoint(x: centerX, y: chainStartY),
            spacing: chainSpacing,
            carabinerType: currentCarabinerType,  // 카라비너 타입 전달
            baseZPosition: baseZPosition
        ) { [weak self] chains in
            guard let self = self else { return }

            for chain in chains {
                chain.physicsBody = nil
                self.addChild(chain)
            }

            // 3. Body 생성
            self.setupBody(
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                bodyImageURL: bodyImageURL,
                baseZPosition: baseZPosition
            )
        }
    }

    /// Body 정적 배치
    private func setupBody(
        chains: [SKSpriteNode],
        centerX: CGFloat,
        chainStartY: CGFloat,
        chainSpacing: CGFloat,
        bodyImageURL: String,
        baseZPosition: CGFloat
    ) {
        KeyringBodyComponent.createNode(from: bodyImageURL) { [weak self] body in
            guard let self = self, let body = body else {
                self?.checkLoadingComplete()
                return
            }

            let bodyFrame = body.calculateAccumulatedFrame()
            let bodyHalfHeight = bodyFrame.height / 2

            let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
            let lastLinkHeight: CGFloat = chains.last.map { $0.calculateAccumulatedFrame().height } ?? chainSpacing
            let lastChainBottomY = lastChainY - lastLinkHeight / 2

            let connectGap = 35.0
            let bodyCenterY = lastChainBottomY - bodyHalfHeight + connectGap

            body.position = CGPoint(x: centerX, y: bodyCenterY)
            body.zPosition = baseZPosition + 1

            // 물리 바디 제거 (정적 배치만)
            body.physicsBody = nil

            self.addChild(body)
            self.checkLoadingComplete()
        }
    }

    // MARK: - Loading Complete

    /// 로딩 완료 확인
    private func checkLoadingComplete() {
        loadedKeyrings += 1

        // 모든 키링, 배경, 카라비너 이미지가 로드되었는지 확인
        let allKeyringsLoaded = loadedKeyrings >= totalKeyrings
        let allAssetsLoaded = allKeyringsLoaded && backgroundLoaded && carabinerBackLoaded && carabinerFrontLoaded

        if allAssetsLoaded {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadingComplete?()
            }
        }
    }
}
