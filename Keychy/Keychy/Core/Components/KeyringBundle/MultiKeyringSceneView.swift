//
//  MultiKeyringSceneView.swift
//  Keychy
//
//  Created by Assistant on 11/05/25.
//

import SwiftUI
import SpriteKit
import Lottie

/// 여러 키링을 하나의 씬에 표시하는 SwiftUI View
struct MultiKeyringSceneView: View {
    let keyringDataList: [MultiKeyringScene.KeyringData]
    let ringType: RingType
    let chainType: ChainType
    let backgroundColor: UIColor

    @State private var scene: MultiKeyringScene?
    @State private var particleEffects: [ParticleEffect] = []  // 로티 효과 리스트

    /// 파티클 효과 데이터
    struct ParticleEffect: Identifiable {
        let id = UUID()
        let keyringIndex: Int
        let effectName: String
        let position: CGPoint  // SwiftUI 좌표
    }

    init(
        keyringDataList: [MultiKeyringScene.KeyringData],
        ringType: RingType = .basic,
        chainType: ChainType = .basic,
        backgroundColor: UIColor = .clear
    ) {
        self.keyringDataList = keyringDataList
        self.ringType = ringType
        self.chainType = chainType
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // SpriteKit Scene
                if let scene = scene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                } else {
                    Color.clear
                }

                // Lottie 파티클 효과들 (순서대로 쌓임)
                ForEach(particleEffects) { effect in
                    lottieEffectView(effect: effect, sceneSize: geometry.size)
                }
            }
            .onAppear {
                setupScene(size: geometry.size)
            }
            .onChange(of: keyringDataList) { _, _ in
                setupScene(size: geometry.size)
            }
        }
    }

    private func setupScene(size: CGSize) {
        let newScene = MultiKeyringScene(
            keyringDataList: keyringDataList,
            ringType: ringType,
            chainType: chainType,
            backgroundColor: backgroundColor
        )

        newScene.size = size
        newScene.scaleMode = .resizeFill

        // 파티클 효과 콜백 설정
        newScene.onPlayParticleEffect = { [self] keyringIndex, effectName, spriteKitPosition in
            // SpriteKit 좌표를 SwiftUI 좌표로 변환
            let swiftUIPosition = CGPoint(
                x: spriteKitPosition.x,
                y: size.height - spriteKitPosition.y
            )

            // 파티클 효과 추가 (순서대로 쌓임)
            let effect = ParticleEffect(
                keyringIndex: keyringIndex,
                effectName: effectName,
                position: swiftUIPosition
            )

            DispatchQueue.main.async {
                particleEffects.append(effect)

                // 2.5초 후 제거
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    particleEffects.removeAll { $0.id == effect.id }
                }
            }
        }

        self.scene = newScene
    }

    /// Lottie 효과 뷰
    private func lottieEffectView(effect: ParticleEffect, sceneSize: CGSize) -> some View {
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
