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
    /// 프레임 이미지 캐시
    private static var cachedFrameImage: UIImage?

    /// Firebase Storage에서 프레임 이미지 다운로드
    func downloadPixelFrame() async -> UIImage? {
        // 캐시된 이미지가 있으면 반환
        if let cached = Self.cachedFrameImage {
            return cached
        }

        let urlString = "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FPixel%2FpixelFrame.png?alt=media&token=18ed44b1-39d5-4b89-a030-d271407dfa7c"

        guard let url = URL(string: urlString) else {
            print("프레임 이미지 URL이 잘못되었습니다")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let image = UIImage(data: data) else {
                print("프레임 이미지 데이터를 UIImage로 변환 실패")
                return nil
            }

            // 캐시에 저장
            Self.cachedFrameImage = image
            print("프레임 이미지 다운로드 및 캐싱 완료")
            return image

        } catch {
            print("프레임 이미지 다운로드 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// 픽셀 이미지와 프레임 이미지를 합성
    func composeWithFrame(pixelImage: UIImage, frameImage: UIImage) -> UIImage {
        // 캔버스 크기를 키워서 프레임 이동 시 잘리지 않도록
        let targetSize: CGFloat = 200
        let frameOffsetX: CGFloat = 2.0 // 프레임을 오른쪽으로 2 이동
        let canvasWidth: CGFloat = targetSize + frameOffsetX // 오른쪽만 여유
        let finalSize = CGSize(width: canvasWidth, height: targetSize)

        let renderer = UIGraphicsImageRenderer(size: finalSize)

        return renderer.image { context in
            // 프레임 두께를 고려한 inset 계산
            let horizontalInset: CGFloat = targetSize * 0.08 // 좌우 프레임 두께 8%
            let bottomInset: CGFloat = targetSize * 0.08 // 하단 프레임 두께 8%
            let topInset: CGFloat = targetSize * 0.15 // 상단은 더 띄움 (15%)
            let leftOffset: CGFloat = -2.17 // 프레임 기울기 보정

            let pixelRect = CGRect(
                x: horizontalInset + leftOffset + frameOffsetX,
                y: topInset,
                width: targetSize - horizontalInset * 2,
                height: targetSize - topInset - bottomInset
            )

            // 1. 픽셀 이미지를 프레임 안쪽에 그리기
            pixelImage.draw(in: pixelRect)

            // 2. 프레임을 위에 오버레이 (오른쪽으로 이동)
            frameImage.draw(in: CGRect(x: frameOffsetX, y: 0, width: targetSize, height: targetSize))
        }
    }

    /// 픽셀 그리드를 UIImage로 변환
    /// @param scale: 이미지 크기 배율 (기본 32배 = 480x480)
    func convertGridToImage(scale: CGFloat = 32) -> UIImage? {
        let pixelSize: CGFloat = 1.0
        let imageSize = CGSize(width: 15 * pixelSize * scale, height: 15 * pixelSize * scale)

        let renderer = UIGraphicsImageRenderer(size: imageSize)

        let image = renderer.image { context in
            // 투명 배경
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))

            // 각 픽셀 그리기
            for row in 0..<15 {
                for col in 0..<15 {
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
    func updateBodyImage() async {
        // 1. 픽셀 그리드를 이미지로 변환
        guard let pixelImage = convertGridToImage() else {
            print("픽셀 이미지 생성 실패")
            return
        }

        // 2. 프레임 이미지 다운로드
        guard let frameImage = await downloadPixelFrame() else {
            print("프레임 이미지 다운로드 실패 - 픽셀 이미지만 사용")
            bodyImage = pixelImage
            hookOffsetY = 0
            return
        }

        // 3. 프레임과 픽셀 이미지 합성
        bodyImage = composeWithFrame(pixelImage: pixelImage, frameImage: frameImage)

        // 픽셀 키링 훅 오프셋
        hookOffsetY = 0.04
    }
}
