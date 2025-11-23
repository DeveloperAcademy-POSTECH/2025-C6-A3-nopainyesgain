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
