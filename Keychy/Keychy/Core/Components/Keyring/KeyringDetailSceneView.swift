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
    let availableHeight: CGFloat
    
    @State private var scene: KeyringDetailScene?
    @State private var showEffect: Bool = false
    @State private var currentEffect: String = ""
    @State private var lottieID = UUID()
    @State private var isLoading: Bool = true
    
    private var calculatedZoomScale: CGFloat {
        // 560일 때 1.0, 267일 때 0.6 정도로 선형 보간
        let maxHeight: CGFloat = 633
        let minHeight: CGFloat = 267
        let maxZoom: CGFloat = 2.0
        let minZoom: CGFloat = 1.8
        
        // 선형 보간
        let ratio = (availableHeight - minHeight) / (maxHeight - minHeight)
        return minZoom + (maxZoom - minZoom) * ratio
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                sceneView
                    .opacity(isLoading ? 0.3 : 1.0)
                
                if showEffect { lottieEffectView }
                
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("키링을 불러오는 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(height: availableHeight) // 높이 제한
            .frame(maxWidth: .infinity) // 너비는 전체
            .position(x: geometry.size.width / 2, y: availableHeight / 2)
            .onAppear {
                if scene == nil {
                    initializeScene(size: CGSize(
                        width: geometry.size.width,
                        height: availableHeight)
                                    )
                }
            }
            .onChange(of: availableHeight) { oldValue, newValue in
                updateSceneSize(width: geometry.size.width, height: newValue)
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
            targetSize: size,
            zoomScale: calculatedZoomScale,
            onLoadingComplete: { // 로딩 완료 콜백
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isLoading = false
                    }
                }
            }
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
        
        // 저장된 사운드/파티클 ID 적용
        if keyring.soundId != "none" {
            newScene.currentSoundId = keyring.soundId
        }
        if keyring.particleId != "none" {
            newScene.currentParticleId = keyring.particleId
        }
        
        scene = newScene
    }
    
    private func updateSceneSize(width: CGFloat, height: CGFloat) {
        guard let scene = scene else { return }
        
        let newSize = CGSize(width: width, height: height)
        
        scene.updateForNewSize(newSize, zoomScale: calculatedZoomScale)
    }
    
    // 노드 안정화 (조인트 재정렬)
    private func stabilizeNodes(scene: KeyringDetailScene) {
        // 모든 노드의 속도 초기화
        scene.chainNodes.forEach { chain in
            chain.physicsBody?.velocity = .zero
            chain.physicsBody?.angularVelocity = 0
        }
        scene.bodyNode?.physicsBody?.velocity = .zero
        scene.bodyNode?.physicsBody?.angularVelocity = 0
        
        // 약간의 중력 임펄스로 정렬
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scene.chainNodes.forEach { chain in
                chain.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -0.5))
            }
        }
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
