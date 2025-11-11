//
//  MultiKeyringCaptureScene+Capture.swift
//  Keychy
//
//  Created by Rundo on 11/10/25.
//

import Foundation
import SpriteKit
import SwiftUI
import UIKit

extension MultiKeyringCaptureScene {

    // MARK: - Instance Methods

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

    // MARK: - Static Helper Methods

    /// 번들 이미지 캡처
    /// - Parameters:
    ///   - keyringDataList: 키링 데이터 리스트
    ///   - backgroundImageURL: 배경 이미지 URL
    ///   - customSize: 커스텀 사이즈 (nil이면 기본 크기 195x422 사용)
    /// - Returns: 캡처된 PNG 데이터
    static func captureBundleImage(
        keyringDataList: [MultiKeyringCaptureScene.KeyringData],
        backgroundImageURL: String,
        customSize: CGSize? = nil
    ) async -> Data? {
        // 고정 캡처 사이즈 (iPhone 13 Pro 비율 기준)
        let captureSize = customSize ?? CGSize(width: 195, height: 422)

        print("📐 [BundleCapture] 캡처 사이즈: \(captureSize.width) x \(captureSize.height)")

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
            scene.size = captureSize
            scene.scaleMode = .aspectFill

            // SKView 생성 및 씬 표시
            let view = SKView(frame: CGRect(origin: .zero, size: captureSize))
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
                    print("⚠️ [BundleCapture] 타임아웃 - 로딩 미완료")
                } else {
                    // 로딩 완료 후 추가 렌더링 대기
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처
                let pngData = await scene.captureToPNG()

                if pngData == nil {
                    print("❌ [BundleCapture] 캡처 실패")
                }

                continuation.resume(returning: pngData)
            }
        }
    }
}
