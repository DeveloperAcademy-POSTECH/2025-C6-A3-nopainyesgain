//
//  PixelKeyringVM+ImageConversion.swift
//  Keychy
//
//  Created by 길지훈 on 11/22/25.
//

import SwiftUI
import UIKit

// MARK: - Image Conversion
extension PixelVM {
    /// 픽셀 그리드를 UIImage로 변환
    /// @param scale: 이미지 크기 배율 (기본 32배 = 512x512)
    func convertGridToImage(scale: CGFloat = 32) -> UIImage? {
        let pixelSize: CGFloat = 1.0
        let imageSize = CGSize(width: 16 * pixelSize * scale, height: 16 * pixelSize * scale)

        let renderer = UIGraphicsImageRenderer(size: imageSize)

        let image = renderer.image { context in
            // 투명 배경
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))

            // 각 픽셀 그리기
            for row in 0..<16 {
                for col in 0..<16 {
                    let color = pixelGrid[row][col]

                    // .clear는 건너뛰기
                    if color == .clear { continue }

                    let rect = CGRect(
                        x: CGFloat(col) * pixelSize * scale,
                        y: CGFloat(row) * pixelSize * scale,
                        width: pixelSize * scale,
                        height: pixelSize * scale
                    )

                    UIColor(color).setFill()
                    context.fill(rect)
                }
            }
        }

        return image
    }

    /// bodyImage 업데이트 (커스터마이징 뷰로 이동하기 전 호출)
    func updateBodyImage() {
        bodyImage = convertGridToImage()

        // 픽셀 키링은 중앙 정렬이므로 hookOffsetY = 0
        hookOffsetY = 0
    }
}
