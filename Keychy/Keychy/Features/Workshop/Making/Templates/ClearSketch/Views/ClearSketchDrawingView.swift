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
        .alert("작업을 취소하시겠습니까?", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) { }
            Button("확인", role: .destructive) {
                viewModel.resetAll()
                router.reset()
            }
        } message: {
            Text("지금까지 작업한 내용이 모두 초기화됩니다.")
        }
    }
}

// MARK: - Toolbar
extension ClearSketchDrawingView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                showResetAlert = true
            }
        } center: {
            Text("그림을 그려주세요")
                .typography(.notosans17M)
        } trailing: {
            NextToolbarButton {
                viewModel.finalizeDrawing()
                
                if let image = captureDrawingCanvas() {
                    viewModel.captureCanvasImage(image)
                    router.push(.clearSketchCrop)
                } else {
                    print("이미지 생성 실패")
                }
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
        GeometryReader { geometry in
            ZStack {
                // 캔버스 배경
                Color.white
                    //.border(Color.gray.opacity(0.3), width: 1) // 이후 캔버스 영역 체크용
                
                // 그리기 캔버스
                ClearSketchDrawingCanvasView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.canvasSize = geometry.size
            }
        }
    }
    
    private func captureDrawingCanvas() -> UIImage? {
        return createImageDirectly()
    }
    
    @MainActor
    private func createImageDirectly() -> UIImage? {
        // 실제 캔버스의 GeometryReader 크기 사용
        let actualCanvasSize = viewModel.canvasSize.width > 0 ? viewModel.canvasSize :
            CGSize(width: screenWidth, height: screenWidth * 1.2)

        let renderer = UIGraphicsImageRenderer(size: actualCanvasSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // 흰색 배경
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: actualCanvasSize))
            
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
            // 그려진 패스들 렌더링
            for path in viewModel.drawingPaths {
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
                    // 점 하나일 때는 원으로 그리기
                    cgContext.beginPath()
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
