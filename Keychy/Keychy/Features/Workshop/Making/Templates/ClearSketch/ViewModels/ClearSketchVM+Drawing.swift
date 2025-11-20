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
    var availableColors: [Color] {
        [.black, .red, .blue, .green, .yellow, .orange, .purple, .pink, .brown]
    }
    
    var isEraserMode: Bool {
        get { isEraser }
        set { isEraser = newValue }
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
    
    func setCanvasController(_ controller: DrawingCanvasController) {
        canvasController = controller
    }
    
    func selectColor(_ color: Color) {
        currentColor = color
        isEraser = false
        canvasController?.updateDrawingSettings()
    }
    
    func toggleEraser() {
        isEraser.toggle()
        canvasController?.updateDrawingSettings()
    }
    
    func performUndo() {
        guard !drawingPaths.isEmpty else { return }
        let lastPath = drawingPaths.removeLast()
        undoneDrawingPaths.append(lastPath)
        canvasController?.redrawCanvas()
    }
    
    func performRedo() {
        guard !undoneDrawingPaths.isEmpty else { return }
        let path = undoneDrawingPaths.removeLast()
        drawingPaths.append(path)
        canvasController?.redrawCanvas()
    }
    
    func addNewPath(startPoint: CGPoint) {
        let newPath = DrawingPath(
            points: [startPoint],
            color: isEraser ? .white : currentColor,
            lineWidth: isEraser ? 20 : currentLineWidth,
            isEraser: isEraser
        )
        drawingPaths.append(newPath)
        undoneDrawingPaths.removeAll()
    }
    
    func addPointToCurrentPath(_ point: CGPoint) {
        guard !drawingPaths.isEmpty else { return }
        drawingPaths[drawingPaths.count - 1].points.append(point)
    }
    
    func finalizeDrawing() {
        Task { @MainActor in
            await composeDrawing()
        }
    }
    
    // MARK: - Drawing Composition
    private func composeDrawing() async {
        guard !drawingPaths.isEmpty else {
            bodyImage = nil
            return
        }
        
        isComposingDrawing = true
        defer { isComposingDrawing = false }
        
        bodyImage = await createImageFromPaths()
    }
    
    @MainActor
    private func createImageFromPaths() async -> UIImage? {
        let canvasSize = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.clear(CGRect(origin: .zero, size: canvasSize))
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
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
                
                cgContext.beginPath()
                
                if points.count == 1 {
                    cgContext.addArc(
                        center: points[0],
                        radius: path.lineWidth / 2,
                        startAngle: 0,
                        endAngle: .pi * 2,
                        clockwise: true
                    )
                    cgContext.fillPath()
                } else {
                    cgContext.move(to: points[0])
                    for i in 1..<points.count {
                        cgContext.addLine(to: points[i])
                    }
                    cgContext.strokePath()
                }
            }
        }
    }
}

// MARK: - UIViewController & UIView classes (이전과 동일)
class DrawingCanvasController: UIViewController {
    var viewModel: ClearSketchVM?
    private var canvasView: CSDrawingCanvasView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canvasView = CSDrawingCanvasView()
        canvasView.controller = self
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvasView.backgroundColor = .clear
        
        view.addSubview(canvasView)
    }
    
    func updateDrawingSettings() {
        canvasView.updateSettings()
    }
    
    func redrawCanvas() {
        canvasView.setNeedsDisplay()
    }
}

class CSDrawingCanvasView: UIView {
    weak var controller: DrawingCanvasController?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let viewModel = controller?.viewModel else { return }
        
        let point = touch.location(in: self)
        viewModel.addNewPath(startPoint: point)
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let viewModel = controller?.viewModel else { return }
        
        let point = touch.location(in: self)
        viewModel.addPointToCurrentPath(point)
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let viewModel = controller?.viewModel else { return }
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for path in viewModel.drawingPaths {
            if path.isEraser {
                context.setBlendMode(.clear)
            } else {
                context.setBlendMode(.normal)
                context.setStrokeColor(UIColor(path.color).cgColor)
            }
            
            context.setLineWidth(path.lineWidth)
            let points = path.points
            guard points.count > 0 else { continue }
            
            context.beginPath()
            
            if points.count == 1 {
                context.addArc(
                    center: points[0],
                    radius: path.lineWidth / 2,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )
                context.fillPath()
            } else {
                context.move(to: points[0])
                for i in 1..<points.count {
                    context.addLine(to: points[i])
                }
                context.strokePath()
            }
        }
    }
    
    func updateSettings() {
        // 필요시 설정 업데이트
    }
}
