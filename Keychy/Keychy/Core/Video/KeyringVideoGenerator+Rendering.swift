//
//  KeyringVideoGenerator+Rendering.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import Foundation
import AVFoundation
import CoreMedia
import SpriteKit
import Lottie

// MARK: - Rendering

extension KeyringVideoGenerator {

    /// 프레임별 렌더링 수행
    /// Scene을 업데이트하고 GPU로 렌더링하여 비디오에 추가
    func renderFrames() async throws {
        guard let scene = scene,
              let renderer = renderer,
              let commandQueue = commandQueue,
              let adaptor = pixelBufferAdaptor,
              let writerInput = writerInput else {
            throw VideoError.setupFailed
        }

        for frameIndex in 0..<targetFrames {
            let currentTime = Double(frameIndex) / Double(fps)

            triggerEventsIfNeeded(at: frameIndex, currentTime: currentTime)
            updateParticleTexture(at: frameIndex, scene: scene)
            scene.update(currentTime)

            guard let pixelBuffer = createPixelBuffer() else {
                throw VideoError.renderFailed
            }

            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                throw VideoError.renderFailed
            }

            renderer.render(
                withViewport: CGRect(x: 0, y: 0, width: width, height: height),
                commandBuffer: commandBuffer,
                renderPassDescriptor: createRenderPassDescriptor(for: pixelBuffer)
            )

            commandBuffer.commit()
            await commandBuffer.completed()

            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(for: .seconds(0.01))
            }

            let presentationTime = CMTime(
                value: CMTimeValue(frameIndex),
                timescale: CMTimeScale(fps)
            )

            guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                throw VideoError.renderFailed
            }

            try await Task.sleep(for: .seconds(0.0167))
        }
    }

    /// 특정 프레임에서 이벤트 트리거
    /// - 0.5초(30 프레임): 스와이프 임팩트 + 파티클
    /// - 2.5초(150 프레임): 탭 사운드
    func triggerEventsIfNeeded(at frameIndex: Int, currentTime: Double) {
        guard let scene = scene else { return }

        if frameIndex == swipeEventFrame {
            let velocity = CGVector(dx: swipeVelocity, dy: 0)
            scene.applySwipeForceToNearbyChains(
                at: CGPoint(
                    x: scene.size.width / 2,
                    y: scene.size.height / 2
                ),
                velocity: velocity
            )

            // TODO: 오디오 합성
            if scene.currentSoundId != "none" {
                soundEvents.append(SoundEvent(
                    time: 0.5,
                    soundId: scene.currentSoundId
                ))
            }
        }

        if frameIndex == tapSoundEventFrame {
            if scene.currentSoundId != "none" {
                soundEvents.append(SoundEvent(
                    time: 2.5,
                    soundId: scene.currentSoundId
                ))
            }
        }
    }

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
