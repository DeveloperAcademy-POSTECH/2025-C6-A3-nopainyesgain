//
//  MKViewModel+BGRemover.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/16/25.
//

import SwiftUI
import Vision

// MARK: - 배경 제거 (누끼)
extension AcrylicPhotoVM {

    /// 1. 배경만 제거 (크롭 없음, 아크릴 효과 없음)
    static func removeBackground(
        from image: UIImage,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let inputImage = CIImage(image: image) else {
            completion(nil)
            return
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])

                guard let result = request.results?.first else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                // 피사체 마스크 생성
                guard let maskPixelBuffer = try? result.generateScaledMaskForImage(
                    forInstances: result.allInstances,
                    from: handler
                ) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

                // 마스크 스케일 조정
                let scaleX = inputImage.extent.width / maskImage.extent.width
                let scaleY = inputImage.extent.height / maskImage.extent.height
                let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

                // 배경 제거 적용
                guard let filter = CIFilter(name: "CIBlendWithMask") else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                filter.setValue(inputImage, forKey: kCIInputImageKey)
                filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
                filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)

                guard let outputImage = filter.outputImage else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let context = CIContext()
                guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let backgroundRemovedImage = UIImage(
                    cgImage: cgImage,
                    scale: image.scale,
                    orientation: image.imageOrientation
                )

                DispatchQueue.main.async {
                    completion(backgroundRemovedImage)
                }

            } catch {
                print("배경 제거 실패: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    // MARK: - 배경 제거 + 완전 크롭 + 리사이즈 + 아크릴 효과
    static func removeBackgroundAndCrop(
        from originalImage: UIImage,
        completion: @escaping ((image: UIImage, hookOffsetY: CGFloat)?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 0. 미리 화질 줄이기 (긴 변 1024px)
            let downsampled = originalImage.resizeForProcessing(maxDimension: 1024)

            // 1. 배경 제거
            removeBackground(from: downsampled) { backgroundRemovedImage in
                guard let bgRemoved = backgroundRemovedImage else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                // 2. 피사체 기준 완전 크롭
                guard let subjectCropped = bgRemoved.cropToSubject() else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                // 3. 200x200에 맞게 비율 유지 리사이즈
                guard let resized = subjectCropped.resizeToFit(size: CGSize(width: 155, height: 155)) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                // 4. 아크릴 테두리 적용
                guard let (stroked, hookOffsetY) = resized.addAcrylicStroke() else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                DispatchQueue.main.async {
                    completion((image: stroked, hookOffsetY: hookOffsetY))
                }
            }
        }
    }
}
