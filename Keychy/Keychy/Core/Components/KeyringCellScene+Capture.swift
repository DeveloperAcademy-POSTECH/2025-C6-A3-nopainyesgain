//
//  KeyringCellScene+Capture.swift
//  Keychy
//
//  Created by Claude on 11/9/25.
//

import SpriteKit
import SwiftUI

extension KeyringCellScene {
    /// Scene을 PNG 이미지로 캡처 (투명 배경)
    @MainActor
    func captureToPNG() async -> Data? {
        print("📸 [KeyringCapture] 캡처 시작")

        // 기존 배경색 저장
        let originalBackgroundColor = self.backgroundColor
        print("📸 [KeyringCapture] 원본 배경색: \(originalBackgroundColor)")

        // 캡처용 SKView 생성
        let view = SKView(frame: CGRect(origin: .zero, size: self.size))

        // 투명도 설정 (PNG 알파 채널 보존)
        view.allowsTransparency = true
        view.backgroundColor = .clear

        // 캡처 시에만 배경을 투명으로 변경
        self.backgroundColor = .clear
        print("📸 [KeyringCapture] 배경색을 투명으로 변경")

        view.presentScene(self)

        // SpriteKit 렌더링 대기 (이미지 로딩 및 물리 시뮬레이션)
        print("📸 [KeyringCapture] 렌더링 대기 중 (150ms)...")
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // 텍스처 캡처
        guard let texture = view.texture(from: self) else {
            print("❌ [KeyringCapture] 텍스처 생성 실패")
            self.backgroundColor = originalBackgroundColor // 원래 색상 복원
            return nil
        }

        // CGImage 변환 (cgImage()는 Optional이 아님)
        let cgImage = texture.cgImage()

        // UIImage로 변환 후 PNG 데이터 추출
        let image = UIImage(cgImage: cgImage)
        guard let pngData = image.pngData() else {
            print("❌ [KeyringCapture] PNG 데이터 변환 실패")
            self.backgroundColor = originalBackgroundColor // 원래 색상 복원
            return nil
        }

        // 원래 배경색 복원
        self.backgroundColor = originalBackgroundColor
        print("📸 [KeyringCapture] 배경색 복원 완료")

        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(pngData.count), countStyle: .file)
        print("✅ [KeyringCapture] 캡처 완료: \(fileSize)")

        return pngData
    }
}
