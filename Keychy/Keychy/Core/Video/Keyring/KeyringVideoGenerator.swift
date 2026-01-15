//
//  KeyringVideoGenerator.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import Foundation
import SwiftUI
import SpriteKit
import AVFoundation
import Photos
import Metal
import MetalKit
import Lottie

/// 키링 영상 생성기
/// SKRenderer로 GPU 메모리에서 직접 렌더링
///
/// # 영상 생성 플로우
/// 1. **Metal 설정** - GPU 디바이스 및 Command Queue 생성
/// 2. **Scene 생성** - KeyringScene 생성 및 초기화 대기 (Setup 완료까지 최대 5초)
/// 3. **Renderer 설정** - SKRenderer를 Metal 디바이스와 연결
/// 4. **Writer 설정** - AVAssetWriter로 H.264 비디오 인코딩 준비 (1080x1920, 60fps)
/// 5. **프레임 렌더링** - 300 프레임(5초, 60fps)을 GPU로 렌더링하여 비디오에 추가
///    - 0.5초(30 프레임): 스와이프 임팩트 + 파티클 효과 + 사운드
///    - 각 프레임: Scene 업데이트 → GPU 렌더링 → PixelBuffer 생성 → 비디오 추가
/// 6. **사운드 합성** - soundEvents 기반으로 비디오에 사운드 트랙 추가
/// 7. **완성** - 비디오 저장 완료 및 URL 반환
///
/// # 스케일 조정 방식
/// SKRenderer는 Scene을 렌더링 영역 크기에 맞춰서 자동으로 늘려서 렌더링함
/// - Scene 크기: 1080 ÷ keyringScale, 1920 ÷ keyringScale (나눗셈으로 작게 만듦)
/// - 렌더링 영역: 1080 x 1920 (고정)
/// - 결과: 작은 Scene이 렌더링 영역에 맞춰 늘어나면서 keyringScale 배율만큼 확대
///
/// 예시: keyringScale = 4.0
/// - Scene 생성: 1080 ÷ 4 = 270, 1920 ÷ 4 = 480 → 270 x 480 크기
/// - 렌더링: 270 x 480 Scene을 1080 x 1920 영역에 그림
/// - 결과: 자동으로 4배 확대 (270→1080, 480→1920)
/// => 9:16 비율을 정확히 맞추기 위한 로직이라고 이해하면됨.

@MainActor
class KeyringVideoGenerator {

    // MARK: - Configuration
    /// 영상 해상도 (9:16 비율)
    let width = 1080
    let height = 1920

    /// 프레임레이트
    let fps = 30

    /// 영상 길이 (초)
    let duration = 5.0

    /// 총 프레임 수
    var targetFrames: Int {
        Int(duration * Double(fps))
    }

    // MARK: - Event Timing
    /// 스와이프 이벤트 발생 프레임 (0.5초)
    let swipeEventFrame = 15

    /// 스와이프 강도
    let swipeVelocity: CGFloat = 7500

    /// 파티클 지속 프레임 수 (1.5초)
    let particleDuration = 45

    // MARK: - Properties

    var scene: KeyringScene?
    var renderer: SKRenderer?
    var metalDevice: MTLDevice?
    var commandQueue: MTLCommandQueue?

    var videoWriter: AVAssetWriter?
    var writerInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    var soundEvents: [SoundEvent] = []

    var backgroundImage: UIImage?
    var keyringScale: CGFloat = 1.0

    // MARK: - Particle Properties
    var particleSpriteNode: SKSpriteNode?
    var particleAnimation: LottieAnimation?  // 애니메이션 데이터 보관
    var particleLottieView: LottieAnimationView?
    var particleWindow: UIWindow?

    // MARK: - Nested Types

    struct SoundEvent {
        let time: Double
        let soundId: String
    }

    enum VideoError: Error {
        case setupFailed
        case renderFailed
        case saveFailed
    }

    // MARK: - Public Method

    /// 키링 영상 생성
    /// - Parameters:
    ///   - viewModel: 키링 뷰모델
    ///   - backgroundImage: 배경 이미지 (기본: completeBG2)
    ///   - keyringScale: 키링 확대 배율 
    /// - Returns: 생성된 영상 파일 URL
    func generateVideo<VM: KeyringViewModelProtocol>(
        viewModel: VM,
        backgroundImage: UIImage? = UIImage(named: "completeBG2"),
        keyringScale: CGFloat = 3.5
    ) async throws -> URL {
        self.backgroundImage = backgroundImage
        self.keyringScale = keyringScale

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

        // KeyringScene 생성 및 Setup 대기
        var isSceneReady = false
        let scene = createScene(viewModel: viewModel) {
            isSceneReady = true
        }
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

        // Scene 초기 업데이트
        scene.update(0)

        // 프레임별 렌더링
        try await renderFrames()

        // 비디오 완성
        let videoURL = try await finishWriting()

        // 사운드 합성
        let finalURL = try await addSoundToVideo(videoURL: videoURL)

        // 정리
        cleanup()

        return finalURL
    }

    // MARK: - Cleanup

    /// 메모리 정리
    private func cleanup() {
        particleSpriteNode?.removeFromParent()
        particleSpriteNode = nil
        particleAnimation = nil
        particleLottieView = nil
        particleWindow = nil

        scene = nil
        renderer = nil
        metalDevice = nil
        commandQueue = nil
        videoWriter = nil
        writerInput = nil
        pixelBufferAdaptor = nil

        soundEvents.removeAll()
    }
}
