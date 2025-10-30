//
//  KeyringDetailSceneView.swift
//  Keychy
//
//  Created by Jini on 10/31/25.
//

import SwiftUI
import SpriteKit
import Lottie

/// 읽기 전용 키링 뷰 (Detail 화면 전용)
struct KeyringDetailSceneView: View {
    let keyring: Keyring
    
    @State private var scene: KeyringDetailScene?
    @State private var showEffect: Bool = false
    @State private var currentEffect: String = ""
    @State private var lottieID = UUID()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                sceneView
                if showEffect { lottieEffectView }
            }
            .onAppear {
                if scene == nil {
                    initializeScene(size: geometry.size)
                }
            }
        }
    }
    
    private func initializeScene(size: CGSize) {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        let newScene = KeyringDetailScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            targetSize: CGSize(width: 175, height: 233),
            zoomScale: 2.0
        )
        newScene.size = size
        newScene.scaleMode = .aspectFill
        newScene.backgroundColor = .clear
        
        // 파티클 효과 콜백 설정 (읽기 전용이지만 효과는 볼 수 있게)
        newScene.onPlayParticleEffect = { [weak newScene] effectName in
            DispatchQueue.main.async {
                currentEffect = effectName
                lottieID = UUID()
                showEffect = true
            }
        }
        
        // 저장된 사운드/파티클 ID가 있다면 적용
        if keyring.soundId != "none" {
            newScene.currentSoundId = keyring.soundId
        }
        if keyring.particleId != "none" {
            newScene.currentParticleId = keyring.particleId
        }
        
        scene = newScene
        print("✅ DetailKeyringScene initialized with size: \(size)")
    }
}

extension KeyringDetailSceneView {
    /// SpriteKit Scene 표시 뷰
    private var sceneView: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
            } else {
                Color.gray.opacity(0.1) // 로딩 중
            }
        }
    }

    /// Lottie 효과 뷰
    private var lottieEffectView: some View {
        LottieView(
            name: currentEffect,
            loopMode: .playOnce,
            speed: 1.0
        )
        .id(lottieID)
        .allowsHitTesting(false)
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showEffect = false }
            }
        }
    }
}
