//
//  BundleVideoGenerator.swift
//  Keychy
//
//  Created by 길지훈 on 1/14/26.
//

import Foundation
import SpriteKit
import AVFoundation
import Metal
import MetalKit

/// 뭉치 영상 생성기
/// SKRenderer로 GPU에서 직접 렌더링하여 영상 생성
///
/// # 영상 생성 플로우
/// 1. **Metal 설정** - GPU 디바이스 및 Command Queue 생성
/// 2. **Scene 생성** - MultiKeyringScene 생성 및 초기화 대기
/// 3. **Renderer 설정** - SKRenderer를 Metal 디바이스와 연결
/// 4. **Writer 설정** - AVAssetWriter로 H.264 비디오 인코딩 준비 (1080x1920, 30fps)
/// 5. **프레임 렌더링** - 150 프레임(5초, 30fps)을 GPU로 렌더링하여 비디오에 추가
///    - 0.5초(15 프레임): 키링 #2 스와이프
///    - 0.67초(20 프레임): 키링 #1 스와이프
///    - 1.0초(30 프레임): 키링 #3 스와이프
/// 6. **완성** - 비디오 저장 완료 및 URL 반환
///
/// # 스케일 조정 방식
/// - Scene 크기: 1080 ÷ bundleScale, 1920 ÷ bundleScale
/// - 렌더링 영역: 1080 x 1920 (고정)
/// - 결과: Scene이 렌더링 영역에 맞춰 자동으로 bundleScale 배율만큼 확대

@MainActor
class BundleVideoGenerator {

    // MARK: - Configuration

    let width = 1080
    let height = 1920
    let fps = 30
    let duration = 5.0

    var targetFrames: Int {
        Int(duration * Double(fps))
    }

    // MARK: - Swipe Event Timing

    let swipeEventFrames = [15, 20, 30]  // 0.5초, 0.67초, 1.0초
    let swipeOrder = [1, 0, 2]  // 키링 #2 → #1 → #3
    let swipeVelocities: [CGFloat] = [5000, 1600, 3600]

    // MARK: - Properties

    var scene: MultiKeyringScene?
    var renderer: SKRenderer?
    var metalDevice: MTLDevice?
    var commandQueue: MTLCommandQueue?

    var videoWriter: AVAssetWriter?
    var writerInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    var backgroundImage: UIImage?
    var bundleScale: CGFloat = 2.5
    var keyringDataList: [MultiKeyringScene.KeyringData] = []
    var playingParticles: [Int: ParticlePlaybackInfo] = [:]

    // MARK: - Nested Types

    enum VideoError: Error {
        case setupFailed
        case renderFailed
        case saveFailed
    }

    // MARK: - Public Method

    /// 뭉치 영상 생성
    func generateVideo(
        keyringDataList: [MultiKeyringScene.KeyringData],
        backgroundImage: UIImage? = nil,
        backgroundImageURL: String? = nil,
        carabinerBackImageURL: String? = nil,
        carabinerFrontImageURL: String? = nil,
        carabinerX: CGFloat = 0,
        carabinerY: CGFloat = 0,
        carabinerWidth: CGFloat = 0,
        carabinerType: CarabinerType? = nil,
        bundleScale: CGFloat = 2.5
    ) async throws -> URL {
        self.backgroundImage = backgroundImage
        self.bundleScale = bundleScale
        self.keyringDataList = keyringDataList

        // Metal 디바이스 설정
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw VideoError.setupFailed
        }
        metalDevice = device

        // Command Queue 생성
        guard let commandQueue = device.makeCommandQueue() else {
            throw VideoError.setupFailed
        }
        self.commandQueue = commandQueue

        // MultiKeyringScene 생성 및 Setup 대기
        var isSceneReady = false
        let scene = createScene(
            keyringDataList: keyringDataList,
            backgroundImageURL: backgroundImageURL,
            carabinerBackImageURL: carabinerBackImageURL,
            carabinerFrontImageURL: carabinerFrontImageURL,
            carabinerX: carabinerX,
            carabinerY: carabinerY,
            carabinerWidth: carabinerWidth,
            carabinerType: carabinerType,
            setupComplete: {
                isSceneReady = true
            }
        )
        self.scene = scene

        // 임시 SKView로 scene 초기화 (didMove(to:) 트리거)
        let tempView = SKView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        tempView.presentScene(scene)

        // didMove(to:) 실행 대기
        try await Task.sleep(for: .seconds(0.1))

        // Scene Setup 완료 대기 (최대 5초)
        var waitCount = 0
        while !isSceneReady && waitCount < 50 {
            try await Task.sleep(for: .seconds(0.1))
            waitCount += 1
        }

        guard isSceneReady else {
            throw VideoError.setupFailed
        }

        // SKRenderer 생성
        let renderer = SKRenderer(device: device)
        renderer.scene = scene
        self.renderer = renderer

        // AVAssetWriter 설정
        try setupVideoWriter()

        // 프레임별 렌더링
        try await renderFrames()

        // 비디오 완성
        let videoURL = try await finishWriting()

        // 정리
        cleanup()

        return videoURL
    }

    // MARK: - Cleanup

    private func cleanup() {
        scene = nil
        renderer = nil
        metalDevice = nil
        commandQueue = nil
        videoWriter = nil
        writerInput = nil
        pixelBufferAdaptor = nil
        playingParticles.removeAll()
        keyringDataList.removeAll()
    }
}
