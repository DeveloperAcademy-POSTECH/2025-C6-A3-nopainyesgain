//
//  KeyringVideoGenerator+Particle.swift
//  Keychy
//
//  Created by 길지훈 on 1/13/26.
//

import Foundation
import SpriteKit
import Lottie

// MARK: - Particle Effects

extension KeyringVideoGenerator {

    /// 파티클 텍스처 실시간 업데이트
    /// Lottie 애니메이션을 매 프레임마다 이미지로 캡처하여 SKTexture로 변환
    func updateParticleTexture(at frameIndex: Int, scene: KeyringScene) {
        let particleId = scene.currentParticleId
        guard particleId != "none" else { return }

        if frameIndex == swipeEventFrame {
            guard let animation = findParticleAnimation(particleId: particleId) else {
                return
            }

            particleAnimation = animation

            // Main Thread 렌더링 엔진 사용 (오프스크린 렌더링 필수)
            let config = LottieConfiguration(renderingEngine: .mainThread)
            let lottieView = LottieAnimationView(animation: animation, configuration: config)

            lottieView.frame = CGRect(origin: .zero, size: CGSize(width: scene.size.width, height: scene.size.height))
            lottieView.contentMode = .scaleAspectFit
            lottieView.backgroundBehavior = .pauseAndRestore

            lottieView.setNeedsLayout()
            lottieView.layoutIfNeeded()

            particleLottieView = lottieView
            particleWindow = nil

            let sprite = SKSpriteNode()
            sprite.size = CGSize(width: scene.size.width, height: scene.size.height)
            sprite.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
            sprite.zPosition = 100

            scene.addChild(sprite)
            particleSpriteNode = sprite
        }

        let particleEndFrame = swipeEventFrame + particleDuration
        if frameIndex >= swipeEventFrame && frameIndex < particleEndFrame,
           let animation = particleAnimation,
           let lottieView = particleLottieView,
           let sprite = particleSpriteNode {

            let offset = frameIndex - swipeEventFrame
            let progress = CGFloat(offset) / CGFloat(particleDuration)
            let targetFrame = animation.startFrame + (animation.endFrame - animation.startFrame) * progress

            lottieView.currentFrame = AnimationFrameTime(targetFrame)
            lottieView.setNeedsDisplay()
            lottieView.layer.displayIfNeeded()
            CATransaction.flush()

            let renderer = UIGraphicsImageRenderer(bounds: lottieView.bounds)
            let image = renderer.image { context in
                lottieView.layer.render(in: context.cgContext)
            }

            sprite.texture = SKTexture(image: image)
        }

        if frameIndex == particleEndFrame {
            particleSpriteNode?.removeFromParent()
            particleSpriteNode = nil
            particleLottieView = nil
            particleWindow = nil
        }
    }

    /// 파티클 애니메이션 파일 찾기 (Firebase 캐시에서)
    private func findParticleAnimation(particleId: String) -> LottieAnimation? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

        guard FileManager.default.fileExists(atPath: cachedURL.path) else {
            return nil
        }

        return LottieAnimation.filepath(cachedURL.path)
    }
}
