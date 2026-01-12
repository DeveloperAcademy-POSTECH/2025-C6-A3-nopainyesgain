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

            // 이벤트 트리거
            triggerEventsIfNeeded(at: frameIndex, currentTime: currentTime)

            // Scene 업데이트 (물리 시뮬레이션)
            scene.update(currentTime)

            // PixelBuffer 생성
            guard let pixelBuffer = createPixelBuffer() else {
                throw VideoError.renderFailed
            }

            // Command Buffer 생성
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                throw VideoError.renderFailed
            }

            // SKRenderer로 GPU 렌더링
            renderer.render(
                withViewport: CGRect(x: 0, y: 0, width: width, height: height),
                commandBuffer: commandBuffer,
                renderPassDescriptor: createRenderPassDescriptor(for: pixelBuffer)
            )

            // Command Buffer 커밋 및 완료 대기
            commandBuffer.commit()
            await commandBuffer.completed()

            // writerInput이 준비될 때까지 대기
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(for: .seconds(0.01))
            }

            // 비디오에 프레임 추가
            let presentationTime = CMTime(
                value: CMTimeValue(frameIndex),
                timescale: CMTimeScale(fps)
            )

            guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                throw VideoError.renderFailed
            }

            // 프레임 간 대기 (실시간 물리 시뮬레이션)
            try await Task.sleep(for: .seconds(0.0167))
        }
    }

    /// 특정 프레임에서 이벤트 트리거
    /// - 0.5초(30 프레임): 스와이프 임팩트 + 파티클
    /// - 2.5초(150 프레임): 탭 사운드
    func triggerEventsIfNeeded(at frameIndex: Int, currentTime: Double) {
        guard let scene = scene else { return }

        // 0.5초: 스와이프 임팩트
        if frameIndex == swipeEventFrame {
            let velocity = CGVector(dx: swipeVelocity, dy: 0)
            scene.applySwipeForceToNearbyChains(
                at: CGPoint(
                    x: scene.size.width / 2,
                    y: scene.size.height / 2
                ),
                velocity: velocity
            )

            // 파티클 효과
            scene.applyParticleEffect(particleId: scene.currentParticleId)

            // 사운드 이벤트 기록 (TODO: 오디오 합성)
            if scene.currentSoundId != "none" {
                soundEvents.append(SoundEvent(
                    time: 0.5,
                    soundId: scene.currentSoundId
                ))
            }
        }

        // 2.5초: 탭 사운드
        if frameIndex == tapSoundEventFrame {
            if scene.currentSoundId != "none" {
                soundEvents.append(SoundEvent(
                    time: 2.5,
                    soundId: scene.currentSoundId
                ))
            }
        }
    }
}
