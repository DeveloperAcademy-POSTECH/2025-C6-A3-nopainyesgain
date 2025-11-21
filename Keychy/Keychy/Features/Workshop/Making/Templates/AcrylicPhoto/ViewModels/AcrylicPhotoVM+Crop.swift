//
//  MKViewModel+Crop.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/17/25.
//

import SwiftUI

// MARK: - 크롭 관련
extension AcrylicPhotoVM {

    /// 크롭 영역을 이미지 중앙으로 리셋
    func resetToCenter() {
        let displayRect = getDisplayedImageRect()

        // 크롭박스 초기 크기 (이미지의 60%)
        let scale: CGFloat = 0.6
        let newWidth = displayRect.width * scale
        let newHeight = displayRect.height * scale
        let newX = displayRect.midX - newWidth / 2
        let newY = displayRect.midY - newHeight / 2

        cropArea = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
        hasCropAreaBeenSet = true
    }

    /// 실제 이미지가 표시되는 영역 계산 (GeometryReader 좌표계 기준)
    func getDisplayedImageRect() -> CGRect {
        guard let image = fixedImage else { return .zero }

        let imageRatio = image.size.width / image.size.height
        let containerRatio = imageViewSize.width / imageViewSize.height

        var width: CGFloat
        var height: CGFloat
        var x: CGFloat = 0
        var y: CGFloat = 0

        if imageRatio > containerRatio {
            // 이미지가 가로로 더 넓음 → 가로에 맞춤
            width = imageViewSize.width
            height = width / imageRatio
            // imageViewSize 내에서의 y 좌표
            let yInImageView = (imageViewSize.height - height) / 2
            // containerSize 좌표계로 변환
            y = (containerSize.height - imageViewSize.height) / 2 + yInImageView
        } else {
            // 이미지가 세로로 더 김 → 세로에 맞춤 (최대 75%까지만)
            height = imageViewSize.height
            width = height * imageRatio
            // imageViewSize 내에서의 x 좌표
            let xInImageView = (imageViewSize.width - width) / 2
            // containerSize 좌표계로 변환 (y는 imageViewSize가 중앙에 위치)
            x = xInImageView
            y = (containerSize.height - imageViewSize.height) / 2
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
