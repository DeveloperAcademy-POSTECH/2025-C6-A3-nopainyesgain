//
//  BundleVideoGenerator+Rendering.swift
//  Keychy
//
//  Created by Claude Code on 1/14/26.
//

import Foundation
import AVFoundation
import CoreMedia
import SpriteKit

// MARK: - Rendering

extension BundleVideoGenerator {

    /// 프레임별 렌더링 수행
    /// Scene을 업데이트하고 GPU로 렌더링하여 비디오에 추가
    /// 지정된 프레임에서 스와이프 이벤트 트리거
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

            // 스와이프 이벤트 트리거 (프레임 15, 45, 75)
            triggerSwipeEvents(at: frameIndex, scene: scene)

            // Scene 업데이트
            scene.update(currentTime)

            // PixelBuffer 생성
            guard let pixelBuffer = createPixelBuffer() else {
                throw VideoError.renderFailed
            }

            // Metal 렌더링
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

            // Writer가 준비될 때까지 대기
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(for: .seconds(0.01))
            }

            // PixelBuffer를 비디오에 추가
            let presentationTime = CMTime(
                value: CMTimeValue(frameIndex),
                timescale: CMTimeScale(fps)
            )

            guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                throw VideoError.renderFailed
            }

            // 프레임 간 딜레이 (약 60fps 속도로 처리)
            try await Task.sleep(for: .seconds(0.0167))
        }
    }

    /// 스와이프 이벤트 트리거
    /// - Parameters:
    ///   - frameIndex: 현재 프레임 인덱스
    ///   - scene: MultiKeyringScene
    ///
    /// 스와이프 타이밍:
    /// - 프레임 15 (0.5초): 키링 #1 (index 0), 강도 9000
    /// - 프레임 30 (1.0초): 키링 #3 (index 2), 강도 6000
    /// - 프레임 45 (1.5초): 키링 #2 (index 1), 강도 7500
    private func triggerSwipeEvents(at frameIndex: Int, scene: MultiKeyringScene) {
        guard let eventIndex = swipeEventFrames.firstIndex(of: frameIndex) else {
            return
        }

        let keyringIndex = swipeOrder[eventIndex]
        let velocity = swipeVelocities[eventIndex]

        // 스와이프 방향: 오른쪽으로 (dx: 양수, dy: 0)
        let swipeVector = CGVector(dx: velocity, dy: 0)

        scene.applySwipeForceToKeyring(index: keyringIndex, velocity: swipeVector)
    }
}
