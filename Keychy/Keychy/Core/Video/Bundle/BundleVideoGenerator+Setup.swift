//
//  BundleVideoGenerator+Setup.swift
//  Keychy
//
//  Created by Claude Code on 1/14/26.
//

import Foundation
import SpriteKit
import AVFoundation

// MARK: - Setup

extension BundleVideoGenerator {

    /// MultiKeyringScene 생성
    func createScene(
        keyringDataList: [MultiKeyringScene.KeyringData],
        backgroundImageURL: String?,
        carabinerBackImageURL: String?,
        carabinerFrontImageURL: String?,
        carabinerX: CGFloat,
        carabinerY: CGFloat,
        carabinerWidth: CGFloat,
        carabinerType: CarabinerType?,
        setupComplete: @escaping () -> Void
    ) -> MultiKeyringScene {
        let sceneWidth = CGFloat(width) / bundleScale
        let sceneHeight = CGFloat(height) / bundleScale

        let offsetX: CGFloat = 15
        let offsetY: CGFloat = -30
        let adjustedKeyringDataList = keyringDataList.map { data in
            MultiKeyringScene.KeyringData(
                index: data.index,
                position: CGPoint(
                    x: data.position.x + offsetX,
                    y: data.position.y + offsetY
                ),
                bodyImageURL: data.bodyImageURL,
                templateId: data.templateId,
                soundId: data.soundId,
                customSoundURL: data.customSoundURL,
                particleId: data.particleId,
                hookOffsetY: data.hookOffsetY,
                chainLength: data.chainLength
            )
        }

        let scene = MultiKeyringScene(
            keyringDataList: adjustedKeyringDataList,
            ringType: .basic,
            chainType: .basic,
            backgroundColor: .clear,
            backgroundImageURL: backgroundImageURL,
            carabinerBackImageURL: carabinerBackImageURL,
            carabinerFrontImageURL: carabinerFrontImageURL,
            carabinerX: carabinerX + offsetX,
            carabinerY: carabinerY + offsetY,
            carabinerWidth: carabinerWidth
        )
        scene.currentCarabinerType = carabinerType
        scene.scaleMode = .aspectFill
        scene.size = CGSize(width: sceneWidth, height: sceneHeight)

        if let bgImage = backgroundImage {
            let backgroundNode = SKSpriteNode(texture: SKTexture(image: bgImage))
            backgroundNode.size = CGSize(width: sceneWidth, height: sceneHeight)
            backgroundNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight / 2)
            backgroundNode.zPosition = -1000
            scene.addChild(backgroundNode)
        }

        scene.onSetupComplete = {
            setupComplete()
        }

        return scene
    }

    /// AVAssetWriter 설정
    func setupVideoWriter() throws {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bundle_video_\(UUID()).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps
            ]
        ]

        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        input.expectsMediaDataInRealTime = false

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        self.videoWriter = writer
        self.writerInput = input
        self.pixelBufferAdaptor = adaptor
    }

    /// 비디오 완성
    func finishWriting() async throws -> URL {
        writerInput?.markAsFinished()

        guard let videoWriter = videoWriter else {
            throw VideoError.saveFailed
        }

        await videoWriter.finishWriting()

        guard videoWriter.status == .completed else {
            throw VideoError.saveFailed
        }

        return videoWriter.outputURL
    }
}
