//
//  ClearSketchDrawingView.swift
//  Keychy
//
//  Created by Jini on 11/20/25.
//

import SwiftUI

struct ClearSketchDrawingView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: ClearSketchVM

    @State private var isImageLoading = true
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 그리기 캔버스
                drawingCanvasView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 하단 도구 바
                drawingToolsBar
                    .padding(.bottom)
                    .adaptiveBottomPadding()
            }
            
            customNavigationBar
                .adaptiveTopPadding()
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(true)
        .onAppear {
            viewModel.initializeDrawing()
        }
    }
}

// MARK: - Toolbar
extension ClearSketchDrawingView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                //viewModel.resetImageData()
                router.pop()
            }
        } center: {
            Text("그림을 그려주세요") // 가위로 오려주세요
                .typography(.notosans17B)
        } trailing: {
            NextToolbarButton {
                viewModel.finalizeDrawing()
                router.push(.clearSketchCrop)
            }
            .frame(width: 44, height: 44)
            .offset(x: -4)
        }
    }
}

// MARK: - Drawing Canvas
extension ClearSketchDrawingView {
    var drawingCanvasView: some View {
        ZStack {
            // 캔버스 배경
            Color.white
                .border(Color.gray.opacity(0.3), width: 1)
            
            // 그리기 캔버스
            SketchCanvasViewWrapper(viewModel: viewModel)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Drawing Tools Bar
extension ClearSketchDrawingView {
    var drawingToolsBar: some View {
        VStack(spacing: 12) {
            // 상단 도구들 (실행취소, 다시실행, 지우개)
            HStack(spacing: 15) {
                undoRedoButtons
                Spacer()
                eraserButton
            }
            .padding(.horizontal, 20)
            
            // 브러시 크기와 색상
            HStack(spacing: 15) {
                brushSizeSlider
                
                Divider()
                    .frame(height: 30)
                
                colorPalette
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 15)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
    
    var undoRedoButtons: some View {
        HStack(spacing: 15) {
            Button(action: {
                viewModel.performUndo()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.canUndo ? .primary : .gray)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
            .disabled(!viewModel.canUndo)
            
            Button(action: {
                viewModel.performRedo()
            }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.canRedo ? .primary : .gray)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
            .disabled(!viewModel.canRedo)
        }
    }
    
    var eraserButton: some View {
        Button(action: {
            viewModel.toggleEraser()
        }) {
            Image(systemName: viewModel.isEraserMode ? "eraser.fill" : "eraser")
                .font(.system(size: 18))
                .foregroundColor(viewModel.isEraserMode ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(viewModel.isEraserMode ? Color.blue : Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
        }
    }
    
    var brushSizeSlider: some View {
        HStack {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundColor(.gray)
            
            Slider(value: $viewModel.currentLineWidth, in: 1...20, step: 1)
                .frame(width: 80)
                .disabled(viewModel.isEraserMode)
                .opacity(viewModel.isEraserMode ? 0.5 : 1.0)
            
            Image(systemName: "circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
    }
    
    var colorPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.availableColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: viewModel.currentColor == color && !viewModel.isEraserMode ? 3 : 0)
                        )
                        .shadow(radius: 1)
                        .opacity(viewModel.isEraserMode ? 0.5 : 1.0)
                        .onTapGesture {
                            if !viewModel.isEraserMode {
                                viewModel.selectColor(color)
                            }
                        }
                }
            }
            .padding(.horizontal, 5)
        }
        .frame(maxWidth: 200)
    }
}

// MARK: - Canvas Wrapper
struct SketchCanvasViewWrapper: UIViewControllerRepresentable {
    @Bindable var viewModel: ClearSketchVM
    
    func makeUIViewController(context: Context) -> DrawingCanvasController {
        let controller = DrawingCanvasController()
        controller.viewModel = viewModel
        viewModel.setCanvasController(controller)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DrawingCanvasController, context: Context) {
        // ViewModel 변경사항 반영
    }
}
