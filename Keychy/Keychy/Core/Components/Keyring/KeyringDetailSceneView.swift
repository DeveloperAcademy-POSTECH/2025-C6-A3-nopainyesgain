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
    @Binding var isLoading: Bool
    
    @State private var scene: KeyringDetailScene?
    @State private var showEffect: Bool = false
    @State private var currentEffect: String = ""
    @State private var lottieID = UUID()
    @State private var fixedSize: CGSize? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                sceneView
                    .opacity(isLoading ? 0.3 : 1.0)
                
                if showEffect { lottieEffectView }
                
            }
            .frame(width: geometry.size.width, height: fixedSize?.height ?? geometry.size.height, alignment: .top)
            .clipped()
            .onAppear {
                if scene == nil {
                    initializeScene()
                }
            }
            .onDisappear {
                cleanupScene()
            }
        }
    
        
    }
    
    private func initializeScene() {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        let newScene = KeyringDetailScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            hookOffsetY: keyring.hookOffsetY,
            chainLength: keyring.chainLength,
            onLoadingComplete: nil
        )
        
        newScene.onLoadingComplete = { [weak newScene] in
            DispatchQueue.main.async {
                // 씬이 완전히 로드된 후 크기 저장
                if self.fixedSize == nil, let view = newScene?.view {
                    self.fixedSize = view.bounds.size
                }
                
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isLoading = false
                }
            }
        }
        
        newScene.scaleMode = .resizeFill
        newScene.backgroundColor = .clear
        
        newScene.onPlayParticleEffect = { [weak newScene] effectName in
            DispatchQueue.main.async {
                currentEffect = effectName
                lottieID = UUID()
                showEffect = true
            }
        }
        
        if keyring.soundId != "none" {
            newScene.currentSoundId = keyring.soundId
        }
        if keyring.particleId != "none" {
            newScene.currentParticleId = keyring.particleId
        }
        
        scene = newScene
    }
    
    // 메모리 정리
    private func cleanupScene() {
        scene?.removeAllChildren()
        scene?.removeAllActions()
        scene?.physicsWorld.removeAllJoints()
        scene?.view?.presentScene(nil)
        scene = nil
        
        // 이펙트 정리
        showEffect = false
        currentEffect = ""
    }
}

extension KeyringDetailSceneView {
    /// SpriteKit Scene 표시 뷰
    private var sceneView: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .onAppear {
                        scene.isPaused = false
                    }
                    .onDisappear {
                        scene.isPaused = true
                    }
            } else {
                Color.gray.opacity(0.1)
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
