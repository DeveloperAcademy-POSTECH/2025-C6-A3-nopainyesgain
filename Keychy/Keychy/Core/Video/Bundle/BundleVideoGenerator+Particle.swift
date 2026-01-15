//
//  BundleVideoGenerator+Particle.swift
//  Keychy
//
//  Created by 길지훈 on 1/14/26.
//

import Foundation
import SpriteKit
import Lottie

// MARK: - Particle Effects

extension BundleVideoGenerator {

    /// 파티클 재생 정보
    /// 현재 재생 중인 파티클을 렌더링하기 위해 필요한 모든 정보를 담고 있음
    struct ParticlePlaybackInfo {
        let displaySprite: SKSpriteNode           // 화면에 표시되는 스프라이트
        let startedAtFrame: Int                   // 파티클 시작 프레임
        let particleId: String                    // 파티클 ID
        let lottieRenderer: LottieAnimationView   // Lottie → 이미지 변환 렌더러
        let animationData: LottieAnimation        // Lottie 메타데이터 (총 프레임 수 등)
    }

    /// 파티클 업데이트
    func updateParticleTextures(at frameIndex: Int, scene: MultiKeyringScene, keyringDataList: [MultiKeyringScene.KeyringData]) {
        for (eventIndex, eventFrame) in swipeEventFrames.enumerated() {
            if frameIndex == eventFrame {
                let keyringIndex = swipeOrder[eventIndex]
                guard let keyringData = keyringDataList.first(where: { $0.index == keyringIndex }),
                      keyringData.particleId != "none" else {
                    continue
                }
                startParticle(for: keyringIndex, particleId: keyringData.particleId, at: frameIndex, scene: scene)
            }
        }

        let particleIndicesToRemove = playingParticles.keys.filter { keyringIndex in
            updateActiveParticle(for: keyringIndex, at: frameIndex, scene: scene)
        }

        particleIndicesToRemove.forEach { playingParticles.removeValue(forKey: $0) }
    }

    /// 파티클 시작
    private func startParticle(for keyringIndex: Int, particleId: String, at frameIndex: Int, scene: MultiKeyringScene) {
        guard let animation = findParticleAnimation(particleId: particleId) else {
            return
        }

        let config = LottieConfiguration(renderingEngine: .mainThread)
        let lottieView = LottieAnimationView(animation: animation, configuration: config)
        lottieView.frame = CGRect(origin: .zero, size: CGSize(width: scene.size.width, height: scene.size.height))
        lottieView.contentMode = .scaleAspectFit
        lottieView.backgroundBehavior = .pauseAndRestore

        let sprite = SKSpriteNode()
        sprite.size = CGSize(width: scene.size.width, height: scene.size.height)
        sprite.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        sprite.zPosition = 100
        sprite.alpha = 1.0

        scene.addChild(sprite)

        playingParticles[keyringIndex] = ParticlePlaybackInfo(
            displaySprite: sprite,
            startedAtFrame: frameIndex,
            particleId: particleId,
            lottieRenderer: lottieView,
            animationData: animation
        )
    }

    /// 파티클 렌더링
    private func updateActiveParticle(for keyringIndex: Int, at frameIndex: Int, scene: MultiKeyringScene) -> Bool {
        guard let particleInfo = playingParticles[keyringIndex] else {
            return false
        }

        let sprite = particleInfo.displaySprite
        let offset = frameIndex - particleInfo.startedAtFrame
        let targetFrame = particleInfo.animationData.startFrame + CGFloat(offset)

        if targetFrame >= particleInfo.animationData.endFrame {
            sprite.removeFromParent()
            return true
        }

        particleInfo.lottieRenderer.currentFrame = AnimationFrameTime(targetFrame)
        particleInfo.lottieRenderer.setNeedsDisplay()
        particleInfo.lottieRenderer.layer.displayIfNeeded()

        let imageRenderer = UIGraphicsImageRenderer(bounds: particleInfo.lottieRenderer.bounds)
        let image = imageRenderer.image { context in
            particleInfo.lottieRenderer.layer.render(in: context.cgContext)
        }

        sprite.texture = SKTexture(image: image)

        return false
    }

    /// 파티클 애니메이션 찾기
    private func findParticleAnimation(particleId: String) -> LottieAnimation? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

        guard FileManager.default.fileExists(atPath: cachedURL.path) else {
            return nil
        }

        return LottieAnimation.filepath(cachedURL.path)
    }
}
