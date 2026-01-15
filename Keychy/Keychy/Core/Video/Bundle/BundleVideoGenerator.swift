//
//  BundleVideoGenerator.swift
//  Keychy
//
//  Created by Claude Code on 1/14/26.
//

import Foundation
import SwiftUI
import SpriteKit
import AVFoundation
import Photos
import Metal
import MetalKit

/// 뭉치 영상 생성기
/// SKRenderer로 GPU 메모리에서 직접 렌더링
///
/// # 영상 생성 플로우
/// 1. **Metal 설정** - GPU 디바이스 및 Command Queue 생성
/// 2. **Scene 생성** - MultiKeyringScene 생성 및 초기화 대기 (Setup 완료까지 최대 5초)
/// 3. **Renderer 설정** - SKRenderer를 Metal 디바이스와 연결
/// 4. **Writer 설정** - AVAssetWriter로 H.264 비디오 인코딩 준비 (1080x1920, 30fps)
/// 5. **프레임 렌더링** - 150 프레임(5초, 30fps)을 GPU로 렌더링하여 비디오에 추가
///    - 0.5초(15 프레임): 키링 #1 스와이프 (강)
///    - 1.0초(30 프레임): 키링 #3 스와이프 (약)
///    - 1.5초(45 프레임): 키링 #2 스와이프 (중)
///    - 각 프레임: Scene 업데이트 → GPU 렌더링 → PixelBuffer 생성 → 비디오 추가
/// 6. **완성** - 비디오 저장 완료 및 URL 반환 (사운드 없음)
///
/// # 스케일 조정 방식
/// SKRenderer는 Scene을 렌더링 영역 크기에 맞춰서 자동으로 늘려서 렌더링함
/// - Scene 크기: 1080 ÷ bundleScale, 1920 ÷ bundleScale (나눗셈으로 작게 만듦)
/// - 렌더링 영역: 1080 x 1920 (고정)
/// - 결과: 작은 Scene이 렌더링 영역에 맞춰 늘어나면서 bundleScale 배율만큼 확대
///
/// 예시: bundleScale = 2.5
/// - Scene 생성: 1080 ÷ 2.5 = 432, 1920 ÷ 2.5 = 768 → 432 x 768 크기
/// - 렌더링: 432 x 768 Scene을 1080 x 1920 영역에 그림
/// - 결과: 자동으로 2.5배 확대 (432→1080, 768→1920)

@MainActor
class BundleVideoGenerator {

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

    // MARK: - Swipe Event Timing

    /// 스와이프 이벤트 발생 프레임 (3번)
    /// - 15 프레임 (0.5초): 키링 #1 (index 0)
    /// - 30 프레임 (1.0초): 키링 #3 (index 2)
    /// - 45 프레임 (1.5초): 키링 #2 (index 1)
    let swipeEventFrames = [15, 30, 45]

    /// 스와이프 순서 (키링 인덱스)
    /// - [0, 2, 1] = 1번째 → 3번째 → 2번째
    let swipeOrder = [0, 2, 1]

    /// 스와이프 강도 (각 이벤트별)
    /// - 9000: 강 (첫 번째)
    /// - 6000: 약 (두 번째)
    /// - 7500: 중 (세 번째)
    let swipeVelocities: [CGFloat] = [9000, 6000, 7500]

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

    // MARK: - Nested Types

    enum VideoError: Error {
        case setupFailed
        case renderFailed
        case saveFailed
    }

    // MARK: - Public Method

    /// 뭉치 영상 생성
    /// - Parameters:
    ///   - keyringDataList: 키링 데이터 리스트
    ///   - backgroundImage: 배경 이미지
    ///   - backgroundImageURL: 배경 이미지 URL
    ///   - carabinerBackImageURL: 카라비너 뒷면 이미지 URL
    ///   - carabinerFrontImageURL: 카라비너 앞면 이미지 URL
    ///   - carabinerX: 카라비너 X 좌표
    ///   - carabinerY: 카라비너 Y 좌표
    ///   - carabinerWidth: 카라비너 너비
    ///   - carabinerType: 카라비너 타입
    ///   - bundleScale: 뭉치 스케일 (기본값 2.5)
    /// - Returns: 생성된 영상 파일 URL
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
        print("[BundleVideoGenerator] 영상 생성 시작")
        print("[BundleVideoGenerator] 키링 개수: \(keyringDataList.count)")

        self.backgroundImage = backgroundImage
        self.bundleScale = bundleScale

        // Metal 디바이스 설정
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[BundleVideoGenerator] Metal 디바이스 생성 실패")
            throw VideoError.setupFailed
        }
        metalDevice = device
        print("[BundleVideoGenerator] Metal 디바이스 생성 완료")

        // Command Queue 생성
        guard let commandQueue = device.makeCommandQueue() else {
            print("[BundleVideoGenerator] Command Queue 생성 실패")
            throw VideoError.setupFailed
        }
        self.commandQueue = commandQueue
        print("[BundleVideoGenerator] Command Queue 생성 완료")

        // MultiKeyringScene 생성 및 Setup 대기
        print("[BundleVideoGenerator] Scene 생성 시작")
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
                print("[BundleVideoGenerator] Scene Setup 완료 콜백 호출됨")
                isSceneReady = true
            }
        )
        self.scene = scene
        print("[BundleVideoGenerator] Scene 생성 완료, 크기: \(scene.size)")

        // 임시 SKView로 scene 초기화 (didMove(to:) 트리거)
        let tempView = SKView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        tempView.presentScene(scene)
        print("[BundleVideoGenerator] SKView에 Scene 표시 완료")

        // didMove(to:) 실행 대기
        try await Task.sleep(for: .seconds(0.1))

        // Scene Setup 완료 대기 (최대 5초)
        print("[BundleVideoGenerator] Scene Setup 완료 대기 중...")
        var waitCount = 0
        while !isSceneReady && waitCount < 50 {
            try await Task.sleep(for: .seconds(0.1))
            waitCount += 1
            if waitCount % 10 == 0 {
                print("[BundleVideoGenerator] Setup 대기 중... (\(waitCount * 100)ms)")
            }
        }

        guard isSceneReady else {
            print("[BundleVideoGenerator] Scene Setup 타임아웃 (5초 초과)")
            throw VideoError.setupFailed
        }
        print("[BundleVideoGenerator] Scene Setup 완료 확인됨")

        // SKRenderer 생성
        print("[BundleVideoGenerator] Renderer 생성 시작")
        let renderer = SKRenderer(device: device)
        renderer.scene = scene
        self.renderer = renderer
        print("[BundleVideoGenerator] Renderer 생성 완료")

        // AVAssetWriter 설정
        print("[BundleVideoGenerator] VideoWriter 설정 시작")
        try setupVideoWriter()
        print("[BundleVideoGenerator] VideoWriter 설정 완료")

        // Scene 초기 업데이트
        scene.update(0)

        // 프레임별 렌더링
        print("[BundleVideoGenerator] 프레임 렌더링 시작 (총 \(targetFrames) 프레임)")
        try await renderFrames()
        print("[BundleVideoGenerator] 프레임 렌더링 완료")

        // 비디오 완성
        print("[BundleVideoGenerator] 비디오 저장 시작")
        let videoURL = try await finishWriting()
        print("[BundleVideoGenerator] 비디오 저장 완료: \(videoURL)")

        // 정리
        cleanup()

        return videoURL
    }

    // MARK: - Cleanup

    /// 메모리 정리
    private func cleanup() {
        scene = nil
        renderer = nil
        metalDevice = nil
        commandQueue = nil
        videoWriter = nil
        writerInput = nil
        pixelBufferAdaptor = nil
    }
}
