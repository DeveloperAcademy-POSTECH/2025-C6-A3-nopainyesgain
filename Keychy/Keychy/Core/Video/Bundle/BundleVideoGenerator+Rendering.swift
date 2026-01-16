//
//  BundleVideoGenerator+Rendering.swift
//  Keychy
//
//  Created by 길지훈 on 1/14/26.
//

import Foundation
import AVFoundation
import CoreMedia
import SpriteKit

// MARK: - Rendering

extension BundleVideoGenerator {

    /// 프레임 렌더링
    func renderFrames() async throws {
        guard let scene = scene,
              let renderer = renderer,
              let commandQueue = commandQueue,
              let adaptor = pixelBufferAdaptor,
              let writerInput = writerInput else {
            throw VideoError.setupFailed
        }

        for frameIndex in 0..<targetFrames {
            triggerSwipeEvents(at: frameIndex, scene: scene)
            updateParticleTextures(at: frameIndex, scene: scene, keyringDataList: keyringDataList)
            scene.update(CACurrentMediaTime())

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
        }
    }

    /// 스와이프 이벤트 트리거
    private func triggerSwipeEvents(at frameIndex: Int, scene: MultiKeyringScene) {
        for (eventIndex, eventFrame) in swipeEventFrames.enumerated() {
            if frameIndex == eventFrame {
                let keyringIndex = swipeOrder[eventIndex]
                let velocity = swipeVelocities[eventIndex]
                let direction: CGFloat = keyringIndex == 2 ? -1 : 1
                let swipeVector = CGVector(dx: velocity * direction, dy: 0)

                scene.applySwipeForceToKeyring(index: keyringIndex, velocity: swipeVector)
            }
        }
    }
}
