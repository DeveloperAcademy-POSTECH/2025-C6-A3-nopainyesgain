//
//  ClearSketchDrawingCanvasView.swift
//  Keychy
//
//  Created by Jini on 11/23/25.
//

import SwiftUI

struct ClearSketchDrawingCanvasView: View {
    @Bindable var viewModel: ClearSketchVM
    @State private var currentPoints: [CGPoint] = []
    
    var body: some View {
        Canvas { context, size in
            // 기존 패스들 그리기
            for drawingPath in viewModel.drawingPaths {
                drawPath(context: &context, path: drawingPath)
            }
            
            // 현재 그리고 있는 패스
            if !currentPoints.isEmpty {
                let currentPath = DrawingPath(
                    points: currentPoints,
                    color: viewModel.isEraser ? .white : viewModel.currentColor,
                    lineWidth: viewModel.isEraser ? 12 : viewModel.currentLineWidth,
                    isEraser: viewModel.isEraser
                )
                drawPath(context: &context, path: currentPath)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = value.location
                    
                    if currentPoints.isEmpty {
                        currentPoints = [point]
                        startNewPath(at: point)
                    } else {
                        currentPoints.append(point)
                        addPointToCurrentPath(point)
                    }
                }
                .onEnded { _ in
                    finishCurrentPath()
                    currentPoints.removeAll()
                }
        )
        .background(Color.white)
        //.border(Color.gray.opacity(0.3), width: 1) // 이후 캔버스 영역 체크용
    }
    
    // MARK: - 둥근 선 끝으로 패스 그리기
    private func drawPath(context: inout GraphicsContext, path: DrawingPath) {
        
        let points = path.points
        guard points.count > 0 else { return }
        
        if path.isEraser {
            context.blendMode = .clear
        } else {
            context.blendMode = .normal
        }
        
        if points.count == 1 {
            // 점 하나일 때는 원으로 그리기
            let circle = Path(ellipseIn: CGRect(
                x: points[0].x - path.lineWidth / 2,
                y: points[0].y - path.lineWidth / 2,
                width: path.lineWidth,
                height: path.lineWidth
            ))
            
            context.fill(circle, with: .color(path.color))
            
        } else if points.count == 2 {
            // 여러 점일 때는 둥근 선 끝으로 그리기
            var swiftUIPath = Path()
            swiftUIPath.move(to: points[0])
            swiftUIPath.addLine(to: points[1])
            
            context.stroke(
                swiftUIPath,
                with: .color(path.color),
                style: StrokeStyle(
                    lineWidth: path.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        } else {
            // 여러 점일 때는 부드러운 베지어 곡선으로 그리기
            var swiftUIPath = Path()
            swiftUIPath.move(to: points[0])
            
            for i in 1..<points.count {
                let currentPoint = points[i]
                let previousPoint = points[i - 1]
                
                if i == 1 {
                    // 첫 번째 선분은 직선으로
                    swiftUIPath.addLine(to: currentPoint)
                } else {
                    // 이전 점과 현재 점의 중간점을 계산
                    let midPoint = CGPoint(
                        x: (previousPoint.x + currentPoint.x) / 2,
                        y: (previousPoint.y + currentPoint.y) / 2
                    )
                    
                    // 이전 점을 제어점으로 사용하여 부드러운 곡선 생성
                    swiftUIPath.addQuadCurve(
                        to: midPoint,
                        control: previousPoint
                    )
                }
            }
            
            // 마지막 점까지 연결
            if points.count > 1 {
                swiftUIPath.addLine(to: points[points.count - 1])
            }
            
            context.stroke(
                swiftUIPath,
                with: .color(path.color),
                style: StrokeStyle(
                    lineWidth: path.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
    }
    
    private func startNewPath(at point: CGPoint) {
        let newPath = DrawingPath(
            points: [point],
            color: viewModel.isEraser ? .white : viewModel.currentColor,
            lineWidth: viewModel.isEraser ? 12 : viewModel.currentLineWidth,
            isEraser: viewModel.isEraser
        )
        viewModel.drawingPaths.append(newPath)
        viewModel.undoneDrawingPaths.removeAll()
    }
    
    private func addPointToCurrentPath(_ point: CGPoint) {
        guard !viewModel.drawingPaths.isEmpty else { return }
        viewModel.drawingPaths[viewModel.drawingPaths.count - 1].points.append(point)
    }
    
    private func finishCurrentPath() {
        // 패스 완료 시 처리할 로직
    }
}

extension ClearSketchDrawingCanvasView {
    func captureCanvas() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        return renderer.uiImage
    }
}
