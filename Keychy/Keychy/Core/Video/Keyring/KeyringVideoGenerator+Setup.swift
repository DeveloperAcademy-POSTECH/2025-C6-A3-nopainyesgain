//
//  KeyringVideoGenerator+Setup.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import Foundation
import SpriteKit
import AVFoundation

// MARK: - Setup

extension KeyringVideoGenerator {

    /// KeyringScene 생성
    /// Scene 크기를 keyringScale로 나눠서 작게 만들고, Viewport에 렌더링하면 자동 확대
    func createScene<VM: KeyringViewModelProtocol>(
        viewModel: VM,
        setupComplete: @escaping () -> Void
    ) -> KeyringScene {
        let sceneWidth = CGFloat(width) / keyringScale
        let sceneHeight = CGFloat(height) / keyringScale

        let scene = KeyringScene(
            ringType: .basic,
            chainType: .basic,
            bodyImage: viewModel.bodyImage,
            backgroundColor: .clear,
            hookOffsetY: viewModel.hookOffsetY != 0 ? viewModel.hookOffsetY : nil,
            chainLength: viewModel.chainLength
        )
        scene.scaleMode = .aspectFill
        scene.size = CGSize(width: sceneWidth, height: sceneHeight)
        scene.bind(to: viewModel)

        // 배경 이미지 추가
        if let bgImage = backgroundImage {
            let backgroundNode = SKSpriteNode(texture: SKTexture(image: bgImage))
            backgroundNode.size = CGSize(width: sceneWidth, height: sceneHeight)
            backgroundNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight / 2)
            backgroundNode.zPosition = -1000
            scene.addChild(backgroundNode)
        }

        // Setup 완료 콜백 설정
        scene.onSetupComplete = {
            setupComplete()
        }

        return scene
    }

    /// AVAssetWriter 설정
    /// H.264 코덱으로 1080x1920 비디오 인코딩
    func setupVideoWriter() throws {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("keyring_video_\(UUID()).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        // 비디오 설정
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        input.expectsMediaDataInRealTime = false

        // PixelBuffer 설정
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

    /// 비디오 작성 완료 및 URL 반환
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
