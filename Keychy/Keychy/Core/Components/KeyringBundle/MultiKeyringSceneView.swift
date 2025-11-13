//
//  MultiKeyringSceneView.swift
//  Keychy
//
//  Created by rundo on 11/05/25.
//

import SwiftUI
import SpriteKit
import Lottie

/// 파티클 효과 데이터 모델
struct ParticleEffect: Identifiable {
    let id = UUID()
    let keyringIndex: Int       // 키링 인덱스
    let effectName: String       // 로티 애니메이션 이름
    let position: CGPoint        // SwiftUI 좌표계 위치
}

/// 여러 키링을 하나의 씬에 표시하는 SwiftUI View
struct MultiKeyringSceneView: View {
    let keyringDataList: [MultiKeyringScene.KeyringData]
    let ringType: RingType
    let chainType: ChainType
    let backgroundColor: UIColor
    let backgroundImageURL: String?
    let carabinerBackImageURL: String?
    let carabinerFrontImageURL: String?
    let carabinerX: CGFloat
    let carabinerY: CGFloat
    let carabinerWidth: CGFloat
    let currentCarabinerType: CarabinerType

    @State private var scene: MultiKeyringScene?
    @State private var particleEffects: [ParticleEffect] = []
    @State private var isSceneReady: Bool = false

    // 기본 화면 크기 (iPhone 14 기준)
    private let defaultSceneSize = CGSize(width: 393, height: 852)

    init(
        keyringDataList: [MultiKeyringScene.KeyringData],
        ringType: RingType = .basic,
        chainType: ChainType = .basic,
        backgroundColor: UIColor = .clear,
        backgroundImageURL: String? = nil,
        carabinerBackImageURL: String? = nil,
        carabinerFrontImageURL: String? = nil,
        carabinerX: CGFloat = 0,
        carabinerY: CGFloat = 0,
        carabinerWidth: CGFloat = 0,
        currentCarabinerType: CarabinerType
    ) {
        self.keyringDataList = keyringDataList
        self.ringType = ringType
        self.chainType = chainType
        self.backgroundColor = backgroundColor
        self.backgroundImageURL = backgroundImageURL
        self.carabinerBackImageURL = carabinerBackImageURL
        self.carabinerFrontImageURL = carabinerFrontImageURL
        self.carabinerX = carabinerX
        self.carabinerY = carabinerY
        self.carabinerWidth = carabinerWidth
        self.currentCarabinerType = currentCarabinerType
    }

    var body: some View {
        ZStack {
            sceneView
            particleEffectsView
        }
        .onAppear { setupScene() }
        .onChange(of: keyringDataList) { _, _ in setupScene() }
        .onChange(of: currentCarabinerType) { _, _ in setupScene() }
    }
}

extension MultiKeyringSceneView {
    /// SpriteKit 씬 뷰
    private var sceneView: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .opacity(isSceneReady ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: isSceneReady)
            } else {
                Color.clear
            }
        }
    }

    /// 파티클 효과 레이어
    private var particleEffectsView: some View {
        ForEach(particleEffects) { effect in
            LottieView(
                name: effect.effectName,
                loopMode: .playOnce,
                speed: 1.0
            )
            .allowsHitTesting(false)
            .frame(width: 300, height: 300)
            .position(effect.position)
            .transition(.opacity)
        }
    }

    /// 씬 초기화 및 설정
    private func setupScene() {
        // 씬 교체 시 준비 상태 리셋
        isSceneReady = false

        let newScene = MultiKeyringScene(
            keyringDataList: keyringDataList,
            ringType: ringType,
            chainType: chainType,
            backgroundColor: backgroundColor,
            backgroundImageURL: backgroundImageURL,
            carabinerBackImageURL: carabinerBackImageURL,
            carabinerFrontImageURL: carabinerFrontImageURL,
            carabinerX: carabinerX,
            carabinerY: carabinerY,
            carabinerWidth: carabinerWidth
        )

        newScene.size = defaultSceneSize
        newScene.scaleMode = .aspectFill
        newScene.currentCarabinerType = currentCarabinerType
        newScene.onPlayParticleEffect = handleParticleEffect
        newScene.onAllKeyringsReady = handleSceneReady

        scene = newScene
    }

    /// 씬 준비 완료 처리
    private func handleSceneReady() {
        DispatchQueue.main.async {
            isSceneReady = true
        }
    }

    /// 파티클 효과 재생 처리
    private func handleParticleEffect(
        keyringIndex: Int,
        effectName: String,
        spriteKitPosition: CGPoint
    ) {
        let swiftUIPosition = convertToSwiftUIPosition(spriteKitPosition)
        let effect = ParticleEffect(
            keyringIndex: keyringIndex,
            effectName: effectName,
            position: swiftUIPosition
        )

        DispatchQueue.main.async {
            particleEffects.append(effect)
            scheduleEffectRemoval(effect)
        }
    }

    /// SpriteKit 좌표를 SwiftUI 좌표로 변환
    private func convertToSwiftUIPosition(_ spriteKitPosition: CGPoint) -> CGPoint {
        CGPoint(
            x: spriteKitPosition.x,
            y: defaultSceneSize.height - spriteKitPosition.y
        )
    }

    /// 파티클 효과 제거 예약 (2.5초 후)
    private func scheduleEffectRemoval(_ effect: ParticleEffect) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            particleEffects.removeAll { $0.id == effect.id }
        }
    }
}
