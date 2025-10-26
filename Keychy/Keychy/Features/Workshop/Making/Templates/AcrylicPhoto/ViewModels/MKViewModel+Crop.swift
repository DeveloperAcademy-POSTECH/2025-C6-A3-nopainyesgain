//
//  MKViewModel+Crop.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/17/25.
//

import SwiftUI

// MARK: - 크롭 관련
extension MKViewModel {

    /// 크롭 영역을 이미지 중앙으로 리셋
    func resetToCenter() {
        let displayRect = getDisplayedImageRect()
        cropArea = displayRect
        hasCropAreaBeenSet = true
    }

    /// 실제 이미지가 표시되는 영역 계산
    func getDisplayedImageRect() -> CGRect {
        guard let image = fixedImage else { return .zero }

        let imageRatio = image.size.width / image.size.height
        let containerRatio = imageViewSize.width / imageViewSize.height

        var width: CGFloat
        var height: CGFloat
        var x: CGFloat = 0
        var y: CGFloat = 0

        if imageRatio > containerRatio {
            width = imageViewSize.width
            height = width / imageRatio
            y = (imageViewSize.height - height) / 2
        } else {
            height = imageViewSize.height
            width = height * imageRatio
            x = (imageViewSize.width - width) / 2
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// 이미지 크롭
    func cropImage(image: UIImage, cropArea: CGRect, containerSize: CGSize) -> UIImage? {
        guard let fixedImage = fixedImage else { return nil }

        let imageRect = getDisplayedImageRect()

        // 크롭 영역을 이미지 좌표계로 변환
        let scaleX = fixedImage.size.width / imageRect.width
        let scaleY = fixedImage.size.height / imageRect.height

        let cropRect = CGRect(
            x: (cropArea.minX - imageRect.minX) * scaleX,
            y: (cropArea.minY - imageRect.minY) * scaleY,
            width: cropArea.width * scaleX,
            height: cropArea.height * scaleY
        )

        guard let cgImage = fixedImage.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: fixedImage.scale, orientation: .up)
    }
}
