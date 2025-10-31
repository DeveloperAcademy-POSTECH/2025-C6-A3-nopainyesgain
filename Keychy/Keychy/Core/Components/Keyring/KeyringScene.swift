//
//  KeyringScene.swift
//  KeytschPrototype
//
//  Created by Jini on 10/16/25.
//

import SwiftUI
import SpriteKit
import Combine
import Lottie

class KeyringScene: SKScene {
    // MARK: - SwiftUI로 콜백 전달용
    var onPlayParticleEffect: ((String) -> Void)?
    
    // MARK: - Properties
    var bodyImage: UIImage? // UIImage용
    var bodyImageURL: String? // Firebase URL용
    var cancellables = Set<AnyCancellable>()
    var currentSoundId: String = "none"
    var currentParticleId: String = "none"

    // MARK: - 선택된 타입들
    var currentRingType: RingType = .basic
    var currentChainType: ChainType = .basic
    var currentBodyType: BodyType = .basic

    // MARK: - 구성 요소들
    var ringNode: SKSpriteNode?
    var chainNodes: [SKSpriteNode] = []
    var bodyNode: SKNode?

    // MARK: - 스와이프 제스처 관련
    var lastTouchLocation: CGPoint?
    var lastTouchTime: TimeInterval = 0
    var swipeStartLocation: CGPoint?

    // MARK: - 이펙트 쓰로틀링
    /// 쓰로틀링(Throttling)은 일정 시간 간격으로 실행 횟수를 제한하는 기법. 이라고 합니다.
    /// 마지막 실행 시간을 기록해두고, 일정 시간이 지나야만 다시 실행할 수 있게!
    /// 과도한 함수 호출을 방지합니다.
    /// ---> 흔들기를 과도하게 했을때, 파티클이 중앙에서 안퍼지고 모여있는게 매우 부자연스러워보여서 추가함.
    var lastParticleTime: TimeInterval = 0

    // MARK: - 배경색 설정
    var customBackgroundColor: UIColor = .gray50

    // MARK: - Init / Deinit
    init(
        ringType: RingType,
        chainType: ChainType,
        bodyImage: UIImage? = nil,
        bodyImageURL: String? = nil,
        backgroundColor: UIColor = .gray50
    ) {

        self.currentRingType = ringType
        self.currentChainType = chainType
        self.bodyImageURL = bodyImageURL
        self.customBackgroundColor = backgroundColor

        if let image = bodyImage {
            self.bodyImage = image.fixedOrientation()
        } else {
            self.bodyImage = nil
        }
        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        removeAllChildren()
        removeAllActions()
        cancellables.removeAll()
    }
    
    // MARK: - ViewModel 바인딩 (Generic)
    func bind<VM: KeyringViewModelProtocol>(to viewModel: VM) {
        viewModel.effectSubject
            .sink { [weak self] (soundId, particleId, type) in
                guard let self = self else { return }
                self.currentSoundId = soundId
                self.currentParticleId = particleId

                switch type {
                case .sound:
                    self.applySoundEffect(soundId: soundId)
                case .particle:
                    self.applyParticleEffect(particleId: particleId)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = customBackgroundColor
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        setupKeyring()
    }
}
