//
//  ClearSketchVM+Drawing.swift
//  Keychy
//
//  Created by Jini on 11/20/25.
//

import SwiftUI
import UIKit

// MARK: - Drawing Extension
extension ClearSketchVM {
    
    // MARK: - Drawing State
    var isEraserMode: Bool {
        get { isEraser }
        set { isEraser = newValue }
    }
    
    var isDrawMode: Bool {
        get { !isEraser }
        set { isEraser = !newValue }
    }
    
    var canUndo: Bool {
        !drawingPaths.isEmpty
    }
    
    var canRedo: Bool {
        !undoneDrawingPaths.isEmpty
    }
    
    // MARK: - Drawing Methods
    func initializeDrawing() {
        drawingPaths.removeAll()
        undoneDrawingPaths.removeAll()
        currentColor = .black
        currentLineWidth = 3.0
        isEraser = false
    }
    
    func selectColor(_ color: Color) {
        currentColor = color
        isEraser = false
    }
    
    func toggleEraser() {
        isEraser.toggle()
    }
    
    func undo() {
        guard !drawingPaths.isEmpty else { return }
        let lastPath = drawingPaths.removeLast()
        undoneDrawingPaths.append(lastPath)
    }
    
    func redo() {
        guard !undoneDrawingPaths.isEmpty else { return }
        let path = undoneDrawingPaths.removeLast()
        drawingPaths.append(path)
    }
    
    func finalizeDrawing() {
        isComposingDrawing = true
    }
    
    func captureCanvasImage(_ image: UIImage) {
        bodyImage = image
        isComposingDrawing = false
    }
    
    // MARK: - 베지어 곡선 포함 이미지 생성
    @MainActor
    func createImageFromDrawingPaths(canvasSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // 흰색 배경
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: canvasSize))
            
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
            // 그려진 패스들 렌더링
            for path in drawingPaths {
                if path.isEraser {
                    cgContext.setBlendMode(.clear)
                } else {
                    cgContext.setBlendMode(.normal)
                    cgContext.setStrokeColor(UIColor(path.color).cgColor)
                }
                
                cgContext.setLineWidth(path.lineWidth)
                let points = path.points
                guard points.count > 0 else { continue }
                
                if points.count == 1 {
                    // 점 하나일 때는 원으로 그리기 (fillColor 명시적으로 설정)
                    cgContext.beginPath()
                    cgContext.setFillColor(UIColor(path.color).cgColor)
                    cgContext.addArc(
                        center: points[0],
                        radius: path.lineWidth / 2,
                        startAngle: 0,
                        endAngle: .pi * 2,
                        clockwise: true
                    )
                    cgContext.fillPath()
                } else if points.count == 2 {
                    // 점 두 개일 때는 직선으로 그리기
                    cgContext.beginPath()
                    cgContext.move(to: points[0])
                    cgContext.addLine(to: points[1])
                    cgContext.strokePath()
                } else {
                    // 여러 점일 때는 부드러운 베지어 곡선으로 그리기
                    cgContext.beginPath()
                    cgContext.move(to: points[0])
                    
                    for i in 1..<points.count {
                        let currentPoint = points[i]
                        let previousPoint = points[i - 1]
                        
                        if i == 1 {
                            // 첫 번째 선분은 직선으로
                            cgContext.addLine(to: currentPoint)
                        } else {
                            // 이전 점과 현재 점의 중간점을 계산
                            let midPoint = CGPoint(
                                x: (previousPoint.x + currentPoint.x) / 2,
                                y: (previousPoint.y + currentPoint.y) / 2
                            )
                            
                            // 이전 점을 제어점으로 사용하여 부드러운 곡선 생성
                            cgContext.addQuadCurve(to: midPoint, control: previousPoint)
                        }
                    }
                    
                    // 마지막 점까지 연결
                    cgContext.addLine(to: points[points.count - 1])
                    cgContext.strokePath()
                }
            }
        }
        
        return image
    }
}
