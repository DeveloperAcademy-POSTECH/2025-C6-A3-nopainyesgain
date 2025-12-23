//
//  NeonSignVM+Drawing.swift
//  Keychy
//
//  Created by Rundo on 11/8/25.
//  그리기 관련 로직
//

import SwiftUI

extension NeonSignVM {

    // MARK: - Drawing Composition

    /// 그림을 bodyImage와 합성
    func composeDrawingWithBodyImage() {
        guard let original = originalBodyImage, !drawingPaths.isEmpty else {
            // 그림이 없으면 원본으로 복원
            if let original = originalBodyImage {
                bodyImage = original
            }
            return
        }

        let imageSize = original.size
        let renderer = UIGraphicsImageRenderer(size: imageSize)

        // 화면 좌표 → 이미지 좌표 변환 비율 계산
        let scaleX = imageSize.width / imageFrame.width
        let scaleY = imageSize.height / imageFrame.height

        let composedImage = renderer.image { context in
            // 1. 원본 이미지 그리기
            original.draw(at: .zero)

            // 2. 그림 경로들 그리기
            let cgContext = context.cgContext

            for drawnPath in drawingPaths {
                // 화면 좌표의 Path를 이미지 좌표로 변환
                var transformedPath = Path()

                drawnPath.path.forEach { element in
                    switch element {
                    case .move(to: let point):
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.move(to: transformedPoint)

                    case .line(to: let point):
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.addLine(to: transformedPoint)

                    case .quadCurve(to: let point, control: let control):
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        let transformedControl = CGPoint(
                            x: (control.x - imageFrame.origin.x) * scaleX,
                            y: (control.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.addQuadCurve(to: transformedPoint, control: transformedControl)

                    case .curve(to: let point, control1: let control1, control2: let control2):
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        let transformedControl1 = CGPoint(
                            x: (control1.x - imageFrame.origin.x) * scaleX,
                            y: (control1.y - imageFrame.origin.y) * scaleY
                        )
                        let transformedControl2 = CGPoint(
                            x: (control2.x - imageFrame.origin.x) * scaleX,
                            y: (control2.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.addCurve(to: transformedPoint, control1: transformedControl1, control2: transformedControl2)

                    case .closeSubpath:
                        transformedPath.closeSubpath()

                    @unknown default:
                        break
                    }
                }

                let cgPath = transformedPath.cgPath

                cgContext.setStrokeColor(UIColor(drawnPath.color).cgColor)
                cgContext.setLineWidth(drawnPath.lineWidth * scaleX)
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)

                cgContext.addPath(cgPath)
                cgContext.strokePath()
            }
        }

        bodyImage = composedImage
    }
}
