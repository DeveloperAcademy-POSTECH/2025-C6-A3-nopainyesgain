//
//  ClearSketchVM+ImageConversion.swift
//  Keychy
//
//  Created by Jini on 11/23/25.
//

import SwiftUI
import UIKit

// MARK: - Image Conversion
extension ClearSketchVM {
    
    /// 크롭 패스로 이미지 크롭하기
    func cropImageWithPath(image: UIImage, cropPath: [CGPoint], imageDisplaySize: CGSize) -> UIImage? {
        guard cropPath.count > 2 else { return image }
        
        // 이미지 실제 크기와 화면 표시 크기의 비율 계산
        let scaleX = image.size.width / imageDisplaySize.width
        let scaleY = image.size.height / imageDisplaySize.height
        
        // 화면 좌표를 이미지 좌표로 변환
        let transformedPoints = cropPath.map { point in
            CGPoint(x: point.x * scaleX, y: point.y * scaleY)
        }
        
        // 크롭 영역의 경계 계산
        let minX = transformedPoints.map { $0.x }.min() ?? 0
        let maxX = transformedPoints.map { $0.x }.max() ?? image.size.width
        let minY = transformedPoints.map { $0.y }.min() ?? 0
        let maxY = transformedPoints.map { $0.y }.max() ?? image.size.height
        
        let cropBounds = CGRect(
            x: max(0, minX),
            y: max(0, minY),
            width: min(image.size.width - minX, maxX - minX),
            height: min(image.size.height - minY, maxY - minY)
        )
        
        // UIGraphicsImageRenderer를 사용한 고품질 크롭
        let renderer = UIGraphicsImageRenderer(size: cropBounds.size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // 크롭 패스 생성 (bounds 기준으로 조정)
            let adjustedPath = CGMutablePath()
            if let firstPoint = transformedPoints.first {
                let adjustedFirstPoint = CGPoint(
                    x: firstPoint.x - cropBounds.origin.x,
                    y: firstPoint.y - cropBounds.origin.y
                )
                adjustedPath.move(to: adjustedFirstPoint)
                
                for point in transformedPoints.dropFirst() {
                    let adjustedPoint = CGPoint(
                        x: point.x - cropBounds.origin.x,
                        y: point.y - cropBounds.origin.y
                    )
                    adjustedPath.addLine(to: adjustedPoint)
                }
                adjustedPath.closeSubpath()
            }
            
            // 클리핑 마스크 적용
            cgContext.addPath(adjustedPath)
            cgContext.clip()
            
            // 이미지를 크롭 영역에 맞게 그리기
            let drawRect = CGRect(
                x: -cropBounds.origin.x,
                y: -cropBounds.origin.y,
                width: image.size.width,
                height: image.size.height
            )
            image.draw(in: drawRect)
        }
    }
    
    // MARK: - 크롭된 이미지 처리 파이프라인
    /// 크롭된 이미지를 리사이즈 + addAcrylicStroke 적용
    static func processImageForKeyring(
        from croppedImage: UIImage,
        completion: @escaping ((image: UIImage, hookOffsetY: CGFloat)?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. 키링 크기에 맞게 리사이즈 (비율 유지)
            guard let resized = croppedImage.resizeToFit(size: CGSize(width: 155, height: 155)) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // 2. addAcrylicStroke 적용
            guard let (stroked, hookOffsetY) = resized.addAcrylicStroke() else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            DispatchQueue.main.async {
                completion((image: stroked, hookOffsetY: hookOffsetY))
            }
        }
    }
    
    /// 키링 커스터마이징용 최종 이미지 처리
    /// 크롭된 이미지를 키링에 적합하게 처리합니다.
    func processImageForCustomizing() async {
        guard croppedImage != UIImage() else {
            print("크롭된 이미지가 없습니다")
            bodyImage = nil
            return
        }
        
        isComposingDrawing = true
        defer { isComposingDrawing = false }
        
        await withCheckedContinuation { continuation in
            Self.processImageForKeyring(from: croppedImage) { result in
                if let result = result {
                    self.bodyImage = result.image
                    self.hookOffsetY = result.hookOffsetY
                } else {
                    // 실패시 원본 이미지 사용
                    self.bodyImage = self.croppedImage
                    self.hookOffsetY = 0.0
                }
                continuation.resume()
            }
        }
    }
    
    /// 배경 제거 (흰색 배경 제거)
    @MainActor
    private func removeBackground(from image: UIImage) async -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return image }
        
        // 원본 이미지 그리기
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let imageData = context.data else { return image }
        let pixelBuffer = imageData.assumingMemoryBound(to: UInt32.self)
        
        // 흰색 및 거의 흰색 배경 제거
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let pixel = pixelBuffer[index]
                
                let red = (pixel >> 24) & 0xFF
                let green = (pixel >> 16) & 0xFF
                let blue = (pixel >> 8) & 0xFF
                let alpha = pixel & 0xFF
                
                // 흰색 또는 거의 흰색인 픽셀을 투명하게 만들기
                if red > 240 && green > 240 && blue > 240 {
                    pixelBuffer[index] = 0 // 완전 투명
                } else if alpha > 0 {
                    // 다른 색상은 알파값 조정
                    let newAlpha = min(255, alpha)
                    pixelBuffer[index] = (red << 24) | (green << 16) | (blue << 8) | newAlpha
                }
            }
        }
        
        guard let newCGImage = context.makeImage() else { return image }
        return UIImage(cgImage: newCGImage)
    }
    
    /// 키링 크기에 맞게 리사이즈 및 최적화
    @MainActor
    private func resizeForKeyring(image: UIImage) async -> UIImage {
        let targetSize = CGSize(width: 200, height: 200) // 키링 적정 크기
        
        // 이미지의 실제 콘텐츠 영역 계산
        let contentBounds = calculateContentBounds(image: image)
        
        // 콘텐츠가 있는 부분만 크롭
        guard let croppedCGImage = image.cgImage?.cropping(to: contentBounds) else {
            return resizeImage(image, to: targetSize)
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage)
        
        // 비율을 유지하면서 타겟 크기에 맞게 리사이즈
        return resizeImage(croppedImage, to: targetSize)
    }
    
    /// 이미지에서 실제 콘텐츠가 있는 영역 계산
    private func calculateContentBounds(image: UIImage) -> CGRect {
        guard let cgImage = image.cgImage else {
            return CGRect(origin: .zero, size: image.size)
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return CGRect(origin: .zero, size: image.size)
        }
        
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        
        let bytesPerPixel = 4 // RGBA
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = bytes[offset + 3] // Alpha 채널
                
                // 투명하지 않은 픽셀 발견
                if alpha > 30 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // 콘텐츠가 없으면 전체 이미지 반환
        if minX >= width || minY >= height {
            return CGRect(origin: .zero, size: image.size)
        }
        
        // 약간의 여백 추가
        let margin = 5
        minX = max(0, minX - margin)
        minY = max(0, minY - margin)
        maxX = min(width - 1, maxX + margin)
        maxY = min(height - 1, maxY + margin)
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    /// 이미지 리사이즈 (비율 유지)
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { context in
            // 투명 배경
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            // 이미지를 중앙에 그리기
            let x = (targetSize.width - newSize.width) / 2
            let y = (targetSize.height - newSize.height) / 2
            
            image.draw(in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
        }
    }
}
