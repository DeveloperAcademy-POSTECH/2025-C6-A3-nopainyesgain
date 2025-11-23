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

    /// 팔레트 표시 여부 (그리기 모드일 때만 표시)
    @State private var showPalette: Bool = true
    
    @State private var showResetAlert = false
    
    /// 커스텀 슬라이더
    @State private var initialThumbPosition: CGFloat = 0
    @State private var currentThumbOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    /// GlassEffect 애니메이션을 위한 네임스페이스
    @Namespace private var unionNamespace
    
    /// 프리셋 색상들과 대응하는 이미지
    private let presetColorsWithImages: [(color: Color, imageName: String)] = [
        (.black, "blackCrayon"),
        (.white, "whiteCrayon"),
        (.red, "redCrayon"),
        (.orange, "orangeCrayon"),
        (.yellow, "yellowCrayon"),
        (.green, "greenCrayon"),
        (.mint, "mintCrayon"),
        (.blue, "blueCrayon"),
        (.purple, "purpleCrayon")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: getNavigationHeight())
                    
                    // MARK: - 드로잉 캔버스
                    ZStack {
                        drawingCanvasView
                    }
                    
                    // MARK: - Undo/Redo/그리기/지우기 버튼
                    HStack {
                        undoRedoButtons
                            .padding(.leading, 18)
                        
                        Spacer()
                        
                        drawEraserButtons
                            .padding(.trailing, 18)
                    }
                    .padding(.bottom, showPalette ? 15 : 30)
                    
                    // MARK: - 색상 팔레트 (애니메이션) - 화면의 13% 높이
                    colorPalette
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: showPalette ? geometry.size.height * 0.13 : 0
                        )
                }
                
                // MARK: - 브러시 굵기 슬라이더
                brushSizeSlider
                
                // MARK: - 커스텀 네비게이션
                customNavigationBar

            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }
}

// MARK: - Toolbar
extension ClearSketchDrawingView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                viewModel.resetImageData()
                router.pop()
            }
        } center: {
            Text("그림을 그려주세요")
                .typography(.notosans17M)
        } trailing: {
            NextToolbarButton {
                viewModel.finalizeDrawing()
                router.push(.clearSketchCrop)
            }
            .frame(width: 44, height: 44)
            .offset(x: -4)
        }
    }
    
    // MARK: - 네비게이션 높이 계산 함수
    private func getNavigationHeight() -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return 84 // 기본값
        }
        
        let safeAreaTop = window.safeAreaInsets.top
        let navigationBarHeight: CGFloat = 44
        let additionalPadding: CGFloat = 8
        
        // SafeArea가 있는 기기 (iPhone X 이후)
        if safeAreaTop > 0 {
            return safeAreaTop + navigationBarHeight + additionalPadding
        } else {
            // 직각형 기기 (SE 등)
            return 20 + navigationBarHeight + additionalPadding // 상태바 + 네비게이션 + 여백
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
            ClearSketchDrawingCanvasView(viewModel: viewModel)
        }
    }
}

// MARK: - Brush Size Slider
extension ClearSketchDrawingView {
    var brushSizeSlider: some View {
        ZStack {
            // 화면 중앙에 브러시 크기 표시 (오버레이)
            HStack {
                // 커스텀 슬라이더
                customSlider
                    .padding(.leading, 10)
                
                Spacer()

            }
            .overlay(
                brushSizeIndicator
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            )

        }
    }
    
    // MARK: - 화면 중앙 브러시 크기 표시
    private var brushSizeIndicator: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    // 브러시 크기 원
                    Circle()
                        .fill(viewModel.currentColor)
                        .frame(
                            width: min(viewModel.currentLineWidth * 2, 60),
                            height: min(viewModel.currentLineWidth * 2, 60)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .shadow(radius: 2)
                        )
                        .animation(.easeInOut(duration: 0.2), value: viewModel.currentLineWidth)
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .opacity(isDragging ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: isDragging)
    }
    
    // MARK: - 커스텀 슬라이더
    private var customSlider: some View {
        VStack(spacing: 12) {
            let trackHeight: CGFloat = 200
            let controlSize: CGFloat = 26
            
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // 슬라이더 트랙
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.black10)
                        .frame(width: 8, height: trackHeight)
                    
                    // 슬라이더 썸 (드래그 가능한 동그라미)
                    let normalizedValue = (viewModel.currentLineWidth - 1) / 19 // 1~20을 0~1로 정규화
                    let thumbPosition = normalizedValue * (trackHeight - controlSize)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: controlSize, height: controlSize)
                        .glassEffect(.regular)
                        .offset(y: -thumbPosition)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                        .gesture(
                            DragGesture(coordinateSpace: .local)
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        initialThumbPosition = thumbPosition
                                        currentThumbOffset = 0
                                    }
                                    
                                    // 드래그 거리만큼 썸 위치 조정
                                    let dragDistance = -value.translation.height
                                    let newThumbPosition = initialThumbPosition + dragDistance
                                    
                                    // 트랙 범위 내로 제한
                                    let clampedPosition = max(0, min(trackHeight - controlSize, newThumbPosition))
                                    currentThumbOffset = clampedPosition - initialThumbPosition
                                    
                                    // 정규화된 위치 (0~1)
                                    let normalizedPosition = clampedPosition / (trackHeight - controlSize)
                                    
                                    // 1~20 범위로 변환
                                    let newLineWidth = 1 + (normalizedPosition * 19)
                                    let roundedLineWidth = round(newLineWidth)
                                    
                                    // 햅틱 피드백 (값이 실제로 변경될 때만)
                                    if Int(viewModel.currentLineWidth) != Int(roundedLineWidth) {
                                        Haptic.impact(style: .light)
                                    }
                                    
                                    viewModel.currentLineWidth = roundedLineWidth
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                        .disabled(viewModel.isEraserMode)
                        .opacity(viewModel.isEraserMode ? 0.5 : 1.0)
                }
            }
            .frame(height: trackHeight + controlSize)
        }
    }
}


// MARK: - Undo/Redo Buttons
extension ClearSketchDrawingView {
    private var undoRedoButtons: some View {
        GlassEffectContainer {
            HStack(spacing: -15) {
                Button {
                    viewModel.undo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.canUndo ? "undoBlack" : "undoGray")
                }
                .disabled(!viewModel.canUndo)
                .glassEffectUnion(id: "undoRedo", namespace: unionNamespace)
                .buttonStyle(.glass)
                
                Button {
                    viewModel.redo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.canRedo ? "redoBlack" : "redoGray")
                }
                .disabled(!viewModel.canRedo)
                .glassEffectUnion(id: "undoRedo", namespace: unionNamespace)
                .buttonStyle(.glass)
            }
        }
    }
}

// MARK: - Draw/Eraser Buttons
extension ClearSketchDrawingView {
    private var drawEraserButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                viewModel.isDrawMode = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPalette = true
                }
                Haptic.impact(style: .medium)
            }) {
                Image(viewModel.isDrawMode ? "drawWhite" : "drawBlack")
            }
            .buttonStyle(.glassProminent)
            .tint(viewModel.isDrawMode ? .main500 : .white100)
            
            
            Button(action: {
                viewModel.isDrawMode = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPalette = false
                }
                Haptic.impact(style: .medium)
            }) {
                Image(viewModel.isDrawMode ? "eraserBlack" : "eraserWhite")
            }
            .buttonStyle(.glassProminent)
            .tint(viewModel.isDrawMode ? .white100 : .main500)
        }
    }
}

// MARK: - Color Palette
extension ClearSketchDrawingView {
    private var colorPalette: some View {
        VStack(spacing: 0) {
            if showPalette {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // 프리셋 색상들
                        ForEach(presetColorsWithImages, id: \.color) { colorData in
                            Button {
                                viewModel.selectColor(colorData.color)
                                Haptic.impact(style: .light)
                            } label: {
                                crayonView(colorData: colorData)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: screenHeight * 0.15)
        .background(
            showPalette ? .gray50 : .clear
        )
        .ignoresSafeArea(edges: .bottom)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showPalette)
    }
    
    @ViewBuilder
    private func crayonView(colorData: (color: Color, imageName: String)) -> some View {
        let isSelected = viewModel.currentColor == colorData.color
        
        ZStack(alignment: .top) {
            Image(colorData.imageName)
                .resizable()
                .frame(width: 37, height: 120)
                .aspectRatio(contentMode: .fit)
                .offset(y: isSelected ? 16 : 50)
                .animation(
                    .interpolatingSpring(
                        stiffness: 300,
                        damping: 20,
                        initialVelocity: isSelected ? 10 : -5
                    ),
                    value: isSelected
                )
        }
        .frame(width: 37)
    }
}
