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
    var bodyImage: UIImage?
    var cancellables = Set<AnyCancellable>()
    var currentKeyring: Keyring = Keyring(name: "키링 이름", bodyImage: "fireworks", soundId: "123", particleId: "123", tags: ["tag1"], createdAt: Date(), authorId: "123", copyCount: 0, selectedTemplate: "acrylic", selectedRing: "basic", selectedChain: "basic", isEditable: true, isPackaged: false, chainLength: 5)

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
    
    // MARK: - Init / Deinit
    init(bodyImage: UIImage? = nil) {
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
        viewModel.keyringSubject
            .sink { [weak self] (keyring, type) in
                guard let self = self else { return }
                self.currentKeyring = keyring

                switch type {
                case .sound:
                    self.applySoundEffect(for: keyring)
                case .particle:
                    self.applyParticleEffect(for: keyring)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .lightGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        setupKeyring()
    }
}
