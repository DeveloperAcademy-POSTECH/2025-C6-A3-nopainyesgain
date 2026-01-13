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

            triggerSoundEvents(at: frameIndex, scene: scene)
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
}
