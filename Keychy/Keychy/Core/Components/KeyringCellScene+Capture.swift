//
//  KeyringCellScene+Capture.swift
//  Keychy
//
//  Created by Rundo on 11/9/25.
//

import SpriteKit
import SwiftUI

extension KeyringCellScene {
    /// Scene을 PNG 이미지로 캡처
    @MainActor
    func captureToPNG() async -> Data? {
        print("📸 [KeyringCapture] 캡처 시작")

        // 캡처용 SKView 생성
        let view = SKView(frame: CGRect(origin: .zero, size: self.size))

        // 투명도 설정 (PNG 알파 채널 보존)
        view.allowsTransparency = true
        view.backgroundColor = .clear

        view.presentScene(self)

        // SpriteKit 렌더링 대기
        print("📸 [KeyringCapture] 렌더링 대기 중 (150ms)...")
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // 텍스처 캡처
        guard let texture = view.texture(from: self) else {
            print("❌ [KeyringCapture] 텍스처 생성 실패")
            return nil
        }

        // CGImage 변환
        let cgImage = texture.cgImage()

        // UIImage로 변환 후 PNG 데이터 추출
        let image = UIImage(cgImage: cgImage)
        guard let pngData = image.pngData() else {
            print("❌ [KeyringCapture] PNG 데이터 변환 실패")
            return nil
        }

        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(pngData.count), countStyle: .file)
        print("✅ [KeyringCapture] 캡처 완료: \(fileSize)")

        return pngData
    }
}
