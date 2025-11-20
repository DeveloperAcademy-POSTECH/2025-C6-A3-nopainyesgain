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
            return nil
        }

        // CGImage 변환
        let cgImage = texture.cgImage()

        // UIImage로 변환 후 PNG 데이터 추출
        let image = UIImage(cgImage: cgImage)
        guard let pngData = image.pngData() else {
            return nil
        }

        return pngData
    }

    // MARK: - Static Helper Methods

    /// 번들 이미지 캡처
    /// - Parameters:
    ///   - keyringDataList: 키링 데이터 리스트
    ///   - backgroundImageURL: 배경 이미지 URL
    ///   - carabinerBackImageURL: 카라비너 뒷면 이미지 URL (hamburger 타입)
    ///   - carabinerFrontImageURL: 카라비너 앞면 이미지 URL (hamburger 타입)
    ///   - carabinerType: 카라비너 타입
    ///   - carabinerX: 카라비너 왼쪽 상단 X 좌표
    ///   - carabinerY: 카라비너 왼쪽 상단 Y 좌표
    ///   - carabinerWidth: 카라비너 너비
    /// - Returns: 캡처된 PNG 데이터
    static func captureBundleImage(
        keyringDataList: [MultiKeyringCaptureScene.KeyringData],
        backgroundImageURL: String,
        carabinerBackImageURL: String? = nil,
        carabinerFrontImageURL: String? = nil,
        carabinerType: CarabinerType? = nil,
        carabinerX: CGFloat = 0,
        carabinerY: CGFloat = 0,
        carabinerWidth: CGFloat = 0,
    ) async -> Data? {
        do {
            try await preloadAllImages(
                keyringDataList: keyringDataList,
                backgroundURL: backgroundImageURL,
                carabinerBackURL: carabinerBackImageURL,
                carabinerFrontURL: carabinerFrontImageURL,
                carabinerType: carabinerType
            )
        } catch {
            return nil
        }
        
        // 고정 캡처 사이즈 (iPhone 16 Pro 기준)
        let captureSize = CGSize(width: 402, height: 874)


        return await withCheckedContinuation { continuation in
            var loadingCompleted = false

            // MultiKeyringCaptureScene 생성 (캡처 전용, 물리 없음)
            let scene = MultiKeyringCaptureScene(
                keyringDataList: keyringDataList,
                carabinerType: carabinerType,
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: backgroundImageURL,
                carabinerBackImageURL: carabinerBackImageURL,
                carabinerFrontImageURL: carabinerFrontImageURL,
                carabinerX: carabinerX,
                carabinerY: carabinerY,
                carabinerWidth: carabinerWidth,
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
                } else {
                    // 로딩 완료 후 추가 렌더링 대기
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처
                let pngData = await scene.captureToPNG()

                continuation.resume(returning: pngData)
            }
        }
    }
    
    // MARK: - Image Preloading (Cache Warming)
    
    /// 모든 이미지를 사전에 로드하여 StorageManager 캐시에 저장
    /// - 캡쳐 전에 호출하여 Scene 내부에서의 이미지 로딩 실패를 방지
    private static func preloadAllImages(
        keyringDataList: [MultiKeyringCaptureScene.KeyringData],
        backgroundURL: String,
        carabinerBackURL: String?,
        carabinerFrontURL: String?,
        carabinerType: CarabinerType?
    ) async throws {
        // 1. 배경 이미지 로드
        _ = try await StorageManager.shared.getImage(path: backgroundURL)
        
        // 2. 모든 키링 bodyImage 병렬 로드
        try await withThrowingTaskGroup(of: Void.self) { group in
            for keyringData in keyringDataList {
                group.addTask {
                    _ = try await StorageManager.shared.getImage(path: keyringData.bodyImageURL)
                }
            }
            try await group.waitForAll()
        }
        
        // 3. 카라비너 이미지 로드
        if carabinerType == .hamburger {
            // 카라비너 뒷 이미지 없으면 패스
            if carabinerBackURL != "none" {
                if let backURL = carabinerBackURL {
                    _ = try await StorageManager.shared.getImage(path: backURL)
                }
            }
            if let frontURL = carabinerFrontURL {
                _ = try await StorageManager.shared.getImage(path: frontURL)
            }
        } else if carabinerType == .plain {
            if let backURL = carabinerBackURL {
                _ = try await StorageManager.shared.getImage(path: backURL)
            }
        }
        
        // 4. 캐시 동기화 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
    }
}
