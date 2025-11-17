//
//  UIImage+Extension.swift
//  SampleKeyring
//
//  Created by rundo on 10/15/25.
//

import SwiftUI
import CoreImage

extension UIImage {
    
    /// orientation을 .up으로 정규화한 이미지 반환
    func fixedOrientation() -> UIImage {
        // 이미 정상 방향이면 그대로 반환
        if imageOrientation == .up {
            return self
        }
        
        // 새로운 컨텍스트에서 이미지를 올바른 방향으로 다시 그리기
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
    
    /// Vision 처리용으로 다운샘플링 (긴 변 기준 1024px, Retina 품질 유지)
    func resizeForProcessing(maxDimension: CGFloat = 1024) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0 // Retina 디스플레이용
        format.opaque = false
        format.preferredRange = .standard
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func resizeToFit(size targetSize: CGSize) -> UIImage? {
        let aspectWidth = targetSize.width / size.width
        let aspectHeight = targetSize.height / size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        let newSize = CGSize(width: size.width * aspectRatio, height: size.height * aspectRatio)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = false
        format.preferredRange = .standard
        
        let resizedImage = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resizedImage
    }
    
    private func findTopOpaqueY(in ciImage: CIImage) -> CGFloat? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data else { return nil }
        let buffer = CFDataGetBytePtr(data)!
        
        let midX = width / 2
        let alphaThreshold: UInt8 = 30
        
        // 중앙 X좌표에서 위에서 아래로 스캔
        for y in 0..<height {
            let pixelIndex = (y * width + midX) * bytesPerPixel
            let alpha = buffer[pixelIndex + 3]
            
            if alpha > alphaThreshold {
                // CGImage의 y를 CIImage 좌표계로 변환
                // CIImage extent의 minY를 고려
                let ciImageY = ciImage.extent.minY + CGFloat(height - 1 - y)
                return ciImageY
            }
        }
        
        return nil
    }
    
    func addAcrylicStroke(width: CGFloat = 14, strokeWidth: CGFloat = 1.5) -> (image: UIImage, hookOffsetY: CGFloat)? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        
        // 1. 크기 관련 기본 설정
        let w = ciImage.extent.width
        let h = ciImage.extent.height
        let maxSide = max(w, h)
        let scaleFactor = maxSide / 200.0
        let adjustedRadius = width * scaleFactor
        let adjustedStroke = strokeWidth * scaleFactor
        let thicknessDepth = adjustedRadius * 0.3

        // 2. 피사체 확장 (아크릴 번짐 효과)
        let dilated = ciImage.applyingFilter("CIMorphologyMaximum", parameters: [kCIInputRadiusKey: adjustedRadius])

        // 2-1. 피사체에 그림자 효과 추가 (새로 추가되는 부분)
        let shadowOffset = adjustedRadius * 0.15
        let shadowBlur = adjustedRadius * 0.3

        // 그림자용 알파 마스크 추출
        let shadowAlpha = ciImage.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])

        // 그림자 오프셋 (왼쪽 위 광원 → 오른쪽 아래로 그림자)
        let shadowTransform = CGAffineTransform(translationX: shadowOffset, y: -shadowOffset)
        let offsetShadow = shadowAlpha.transformed(by: shadowTransform)

        // 그림자 블러
        let blurredShadow = offsetShadow.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: shadowBlur])

        // 그림자 색상 (어두운 회색)
        let shadowColor = CIFilter(name: "CIConstantColorGenerator", parameters: [
            kCIInputColorKey: CIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        ])?.outputImage ?? CIImage.empty()

        // 그림자에 색상 적용
        let coloredShadow = shadowColor.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputMaskImageKey: blurredShadow])

        // 원본 이미지에 그림자 합성
        let imageWithShadow = ciImage.composited(over: coloredShadow)

        // 3. 구멍 중심 좌표 계산
        let topY = findTopOpaqueY(in: dilated) ?? (h + adjustedRadius)
        let circleCenter = CIVector(x: w / 2, y: topY)
        let innerRadius = adjustedRadius / 3.0
        let outerRadius = adjustedRadius / 1.5

        // 4. 외부/내부 원 생성 및 합성
        let outerCircle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": circleCenter,
            "inputRadius0": outerRadius,
            "inputRadius1": outerRadius + 1,
            "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: 1),
            "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 0)
        ])?.outputImage
        let withOuterCircle = outerCircle?.composited(over: dilated) ?? dilated
        let innerCircle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": circleCenter,
            "inputRadius0": innerRadius,
            "inputRadius1": innerRadius + 1,
            "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: 1),
            "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 0)
        ])?.outputImage
        let extended = innerCircle != nil
            ? withOuterCircle.applyingFilter("CISourceOutCompositing", parameters: [kCIInputBackgroundImageKey: innerCircle!])
            : withOuterCircle

        // 5. 알파 추출
        let alphaOnly = extended.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])

        // 6. 광택(Gradient) 생성
        let gradient = CIFilter(name: "CIConstantColorGenerator", parameters: [
            kCIInputColorKey: CIColor(red: 1, green: 1, blue: 1, alpha: 0.05)
        ])?.outputImage ?? CIImage.empty()
        let maskedGradient = gradient.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputMaskImageKey: alphaOnly])

        // 7. 외곽선 생성
        let outerDilated = extended.applyingFilter("CIMorphologyMaximum", parameters: [kCIInputRadiusKey: adjustedStroke])
        let outerAlpha = outerDilated.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
        let strokeMask = outerAlpha.applyingFilter("CISourceOutCompositing", parameters: [kCIInputBackgroundImageKey: alphaOnly])
        let strokeColor = CIFilter(name: "CIConstantColorGenerator", parameters: [
            kCIInputColorKey: CIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.8)
        ])?.outputImage ?? CIImage.empty()
        let maskedStroke = strokeColor.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputMaskImageKey: strokeMask])

        // 8. 두께감 (내부 / 외부 벽면)
        let innerThickness = extended.applyingFilter("CIMorphologyMinimum", parameters: [kCIInputRadiusKey: thicknessDepth])
        let innerThicknessAlpha = innerThickness.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
        let innerThicknessMask = alphaOnly.applyingFilter("CISourceOutCompositing", parameters: [kCIInputBackgroundImageKey: innerThicknessAlpha])

        // 9. 내부 두께 마스크 및 색상 적용
        let topLeftMask = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: w * 0.0, y: h * 1.0),
            "inputPoint1": CIVector(x: w * 0.5, y: h * 0.8),
            "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: 1),
            "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ])?.outputImage
        let innerThicknessWithMask = innerThicknessMask.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputMaskImageKey: topLeftMask ?? CIImage.empty()])

        // 10. 외부 두께 마스크 및 색상 적용
        let outerThickness = outerDilated.applyingFilter("CIMorphologyMaximum", parameters: [kCIInputRadiusKey: thicknessDepth])
        let outerThicknessAlpha = outerThickness.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
        let outerThicknessMask = outerThicknessAlpha.applyingFilter("CISourceOutCompositing", parameters: [kCIInputBackgroundImageKey: outerDilated])
        let bottomRightMask = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: w * 1.0, y: h * 0.0),
            "inputPoint1": CIVector(x: w * 0.5, y: h * 0.2),
            "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: 1),
            "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ])?.outputImage
        let outerThicknessWithMask = outerThicknessMask.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputMaskImageKey: bottomRightMask ?? CIImage.empty()])

        // 11. 두께 색상 적용
        let thicknessColor1 = CIFilter(name: "CIConstantColorGenerator", parameters: [
            kCIInputColorKey: CIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.4)
        ])?.outputImage ?? CIImage.empty()
        let thicknessColor2 = CIFilter(name: "CIConstantColorGenerator", parameters: [
            kCIInputColorKey: CIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
        ])?.outputImage ?? CIImage.empty()
        let innerThicknessLayer = thicknessColor1.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputMaskImageKey: innerThicknessWithMask])
        let outerThicknessLayer = thicknessColor2.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputMaskImageKey: outerThicknessWithMask])

        // 12. Stroke + 두께 레이어 합성
        let strokeWithInner = innerThicknessLayer.composited(over: maskedStroke)
        let finalStroke = outerThicknessLayer.composited(over: strokeWithInner)

        // 13. 최종 합성 (Gradient + Stroke + 원본)
        let withStroke = maskedGradient.composited(over: finalStroke)
        let finalImage = withStroke.composited(over: imageWithShadow)

        // 14. 렌더링
        let context = CIContext()
        let renderExtent = finalImage.extent.union(ciImage.extent).insetBy(dx: -20, dy: -20)
        guard let output = context.createCGImage(finalImage, from: renderExtent) else { return nil }

        // 15. hookOffsetY 계산 (이미지 높이 대비 비율로 저장)
        // CIImage 좌표계 (bottom-left origin):
        // - renderExtent.height: 최종 이미지 상단의 Y 위치 (from bottom)
        // - topY: 구멍 중심의 Y 위치 (from bottom)
        // - 상단에서 구멍까지의 거리: renderExtent.height - topY
        let renderHeight = renderExtent.height
        let hookOffsetYFromTop = renderHeight - topY

        // 이미지 높이 대비 비율로 저장 (0.0 ~ 1.0)
        // Scene에서 실제 body 크기에 맞게 자동 조정됨
        let hookOffsetYRatio = hookOffsetYFromTop / renderHeight

        print("🎯 hookOffsetY 계산 (비율 방식):")
        print("  renderHeight: \(renderHeight)px")
        print("  hookOffsetYFromTop: \(hookOffsetYFromTop)px")
        print("  hookOffsetYRatio: \(hookOffsetYRatio) (\(hookOffsetYRatio * 100)%)")

        // 16. UIImage 반환
        let resultImage = UIImage(cgImage: output, scale: self.scale, orientation: self.imageOrientation)

        return (image: resultImage, hookOffsetY: hookOffsetYRatio)
    }
    
    // 피사체 영역으로 크롭
    func cropToSubject() -> UIImage? {
        guard let bounds = getSubjectBounds() else { return nil }
        guard let cgImage = self.cgImage else { return nil }
        guard let croppedCGImage = cgImage.cropping(to: bounds) else { return nil }
        
        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: self.scale,
            orientation: self.imageOrientation
        )
        return croppedImage
    }
    
    // 피사체 경계 영역 계산
    private func getSubjectBounds() -> CGRect? {
        guard let cgImage = self.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return nil }
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        var minY = height, maxY = 0, minX = width, maxX = 0
        
        // 투명하지 않은 픽셀 찾기
        for y in 0..<height {
            for x in 0..<width {
                let alpha = buffer[(y * width + x) * 4 + 3]
                
                if alpha > 10 {
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                }
            }
        }
        
        guard minY <= maxY && minX <= maxX else { return nil }
        
        return CGRect(
            x: CGFloat(minX),
            y: CGFloat(minY),
            width: CGFloat(maxX - minX + 1),
            height: CGFloat(maxY - minY + 1)
        )
    }

    static func createWelcomeBody(nickname: String) -> UIImage? {
        guard let baseImage = UIImage(named: "welcomeBody") else { return nil }

        let renderer = UIGraphicsImageRenderer(size: baseImage.size)
        return renderer.image { context in
            baseImage.draw(at: .zero)

            let text = "@\(nickname)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "NotoSansKR-Black", size: 15) ?? UIFont.systemFont(ofSize: 35, weight: .black),
                .foregroundColor: UIColor.black
            ]

            let textSize = text.size(withAttributes: attributes)
            let x = (baseImage.size.width - textSize.width) / 2 - 2
            let y = baseImage.size.height * 0.67

            text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
}
