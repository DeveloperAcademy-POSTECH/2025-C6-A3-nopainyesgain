//
//  MultiKeyringCaptureScene+Capture.swift
//  Keychy
//
//  Created by Rundo on 11/10/25.
//

import Foundation
import SpriteKit
import SwiftUI

extension MultiKeyringCaptureScene {
    /// Scene을 PNG 이미지로 캡처
    @MainActor
    func captureToPNG() async -> Data? {
        // 캡처용 SKView 생성
        let view = SKView(frame: CGRect(origin: .zero, size: self.size))

        // 투명도 설정 (PNG 알파 채널 보존)
        view.allowsTransparency = true
        view.backgroundColor = .clear

        view.presentScene(self)

        // SpriteKit 렌더링 대기
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // 텍스처 캡처
        guard let texture = view.texture(from: self) else {
            print("❌ [BundleCapture] 텍스처 생성 실패")
            return nil
        }

        // CGImage 변환
        let cgImage = texture.cgImage()

        // UIImage로 변환 후 PNG 데이터 추출
        let image = UIImage(cgImage: cgImage)
        guard let pngData = image.pngData() else {
            print("❌ [BundleCapture] PNG 데이터 변환 실패")
            return nil
        }

        return pngData
    }
}

/// 번들 이미지 캡처를 위한 Helper 클래스
class BundleImageCaptureHelper {

    /// 번들 이미지 캡처
    /// - Parameters:
    ///   - keyringDataList: 키링 데이터 리스트
    ///   - backgroundImageURL: 배경 이미지 URL
    ///   - size: 캡처 이미지 사이즈 (기본값: 350x466)
    /// - Returns: 캡처된 PNG 데이터
    static func captureBundleImage(
        keyringDataList: [MultiKeyringCaptureScene.KeyringData],
        backgroundImageURL: String,
        size: CGSize = CGSize(width: 350, height: 466)
    ) async -> Data? {
        return await withCheckedContinuation { continuation in
            var loadingCompleted = false

            // MultiKeyringCaptureScene 생성 (캡처 전용, 물리 없음)
            let scene = MultiKeyringCaptureScene(
                keyringDataList: keyringDataList,
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: backgroundImageURL,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.size = size
            scene.scaleMode = .aspectFill

            // SKView 생성 및 씬 표시
            let view = SKView(frame: CGRect(origin: .zero, size: size))
            view.allowsTransparency = true
            view.presentScene(scene)

            // 로딩 완료 대기
            Task {
                var waitTime = 0.0
                let checkInterval = 0.1
                let maxWaitTime = 3.0

                while !loadingCompleted && waitTime < maxWaitTime {
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }

                if !loadingCompleted {
                    print("⚠️ [BundleImageCaptureHelper] 타임아웃 - 로딩 미완료")
                } else {
                    // 로딩 완료 후 추가 렌더링 대기
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처
                let pngData = await scene.captureToPNG()

                if pngData == nil {
                    print("❌ [BundleImageCaptureHelper] 캡처 실패")
                }

                continuation.resume(returning: pngData)
            }
        }
    }
}

