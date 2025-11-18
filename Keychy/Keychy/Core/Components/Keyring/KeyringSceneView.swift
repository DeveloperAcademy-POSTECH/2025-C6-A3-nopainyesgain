//
//  KeyringSceneView.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

import SwiftUI
import SpriteKit
import Lottie

/// 키링 SpriteKit Scene + 로티재생 ZStack뷰 (Generic)
struct KeyringSceneView<VM: KeyringViewModelProtocol>: View {
    @Bindable var viewModel: VM
    var backgroundColor: UIColor = .gray50
    var applyWelcomeImpulse: Bool = false  // 씬 준비 완료 시 자동 파티클 효과
    var onSceneReady: (() -> Void)? = nil  // 씬 준비 완료 콜백

    @State private var scene: KeyringScene? = nil
    @State private var showEffect: Bool = false
    @State private var currentEffect: String = ""
    @State private var lottieID = UUID()

    var body: some View {
        ZStack {
            sceneView
            if showEffect { lottieEffectView }
        }
        .onAppear {
            if scene == nil {
                let newScene = KeyringScene(
                    ringType: .basic,
                    chainType: .basic,
                    bodyImage: viewModel.bodyImage,
                    backgroundColor: backgroundColor,
                    hookOffsetY: viewModel.hookOffsetY != 0 ? viewModel.hookOffsetY : nil
                )
                newScene.scaleMode = .resizeFill
                newScene.bind(to: viewModel)

                // Setup 완료 콜백 설정 (Body까지 완전히 생성된 시점)
                newScene.onSetupComplete = {
                    DispatchQueue.main.async {
                        onSceneReady?()

                        // 환영 효과: Setup 완료 후 파티클 터뜨리기
                        if applyWelcomeImpulse {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                newScene.applyWelcomeImpulse()
                            }
                        }
                    }
                }

                scene = newScene
            }
        }
        .task {
            scene?.onPlayParticleEffect = { effectName in
                DispatchQueue.main.async {
                    currentEffect = effectName
                    lottieID = UUID()
                    showEffect = true
                }
            }
        }
    }
}

extension KeyringSceneView {
    /// SpriteKit Scene 표시 뷰
    private var sceneView: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    //.frame(maxWidth: .infinity, minHeight: 400)
                    .frame(maxWidth: .infinity)
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
