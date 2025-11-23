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
}
