//
//  PixelDrawView.swift
//  Keychy
//
//  Created by 길지훈 on 11/22/25.
//

import SwiftUI

struct PixelDrawView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: PixelVM
    
    /// 팔레트 표시 여부 (그리기 모드일 때만 표시)
    @State private var showPalette: Bool = true
    
    /// GlassEffect 애니메이션을 위한 네임스페이스
    @Namespace private var unionNamespace
    
    /// 프리셋 색상들
    private let presetColors: [Color] = [
        .black,
        .white,
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        Color(red: 0, green: 0, blue: 0.5), // Navy
        .purple
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 118)
                    
                    // MARK: - 픽셀 그리드
                    pixelGrid
                        .padding(.horizontal, 18)
                    
                    Spacer()
                        .frame(height: 72)
                    
                    // MARK: - Undo/Redo/그리기/지우기 버튼
                    HStack {
                        undoRedoButtons
                            .padding(.horizontal, 16)
                        
                        drawEraserButtons
                            .padding(.horizontal, 16)
                    }
                    // MARK: - 색상 팔레트 (애니메이션) - 화면의 15% 높이
                    colorPalette
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: showPalette ? geometry.size.height * 0.15 : 0
                        )
                }
                
                // MARK: - 커스텀 네비게이션
                customNavigationBar
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }
}

// MARK: - Pixel Grid
extension PixelDrawView {
    private var pixelGrid: some View {
        GeometryReader { geometry in
            let gridSize = min(geometry.size.width, geometry.size.height * 0.5)
            let cellSize = gridSize / 16
            
            VStack(spacing: 0) {
                ForEach(0..<16, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<16, id: \.self) { col in
                            PixelCell(
                                color: viewModel.pixelGrid[row][col],
                                size: cellSize,
                                onTap: {
                                    viewModel.paintPixel(row: row, col: col)
                                }
                            )
                        }
                    }
                }
            }
            .frame(width: gridSize, height: gridSize)
            .background(Color.white)
            .border(.gray100, width: 1)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let location = value.location
                        let gridOriginX = (geometry.size.width - gridSize) / 2
                        let gridOriginY = (geometry.size.height - gridSize) / 2
                        
                        let relativeX = location.x - gridOriginX
                        let relativeY = location.y - gridOriginY
                        
                        let col = Int(relativeX / cellSize)
                        let row = Int(relativeY / cellSize)
                        
                        viewModel.paintPixel(row: row, col: col)
                    }
            )
        }
        .frame(maxHeight: 366)
    }
}

// MARK: - Pixel Cell
struct PixelCell: View {
    let color: Color
    let size: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .border(.gray100, width: 1)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Undo/Redo Buttons
extension PixelDrawView {
    private var undoRedoButtons: some View {
        GlassEffectContainer {
            HStack {
                Button {
                    viewModel.undo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.undoStack.isEmpty ? "undoGray" : "undoBlack")
                }
                .disabled(viewModel.undoStack.isEmpty)
                .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                .buttonStyle(.glass)
                
                Button {
                    viewModel.redo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.undoStack.isEmpty ? "redoGray" : "redoBlack")
                }
                .disabled(viewModel.redoStack.isEmpty)
                .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                .buttonStyle(.glass)
            }
        }
    }
}

// MARK: - Draw/Eraser Buttons
extension PixelDrawView {
    private var drawEraserButtons: some View {
        HStack(spacing: 8) {
            CircleGlassButton(imageName: viewModel.isDrawMode ? "drawWhite" : "drawBlack") {
                viewModel.isDrawMode = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPalette = true
                }
                Haptic.impact(style: .medium)
            }
            .buttonStyle(.glassProminent)
            .tint(viewModel.isDrawMode ? .main500 : .white)
            
            CircleGlassButton(imageName: viewModel.isDrawMode ? "eraserBlack" : "eraserWhite") {
                viewModel.isDrawMode = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPalette = false
                }
                Haptic.impact(style: .medium)
            }
            .buttonStyle(.glassProminent)
            .tint(viewModel.isDrawMode ? .white : .main500)
        }
    }
}

// MARK: - Color Palette
extension PixelDrawView {
    private var colorPalette: some View {
        VStack(spacing: 0) {
            if showPalette {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        // ColorPicker
                        ColorPicker("", selection: $viewModel.selectedColor)
                            .labelsHidden()
                            .frame(width: 37, height: 37)
                        // 프리셋 색상들
                        ForEach(presetColors, id: \.self) { color in
                            Button {
                                viewModel.selectedColor = color
                                Haptic.impact(style: .light)
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 37, height: 37)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .background(.gray50)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showPalette)
    }
}

// MARK: - Custom Navigation Bar
extension PixelDrawView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                viewModel.resetPixelData()
                router.pop()
            }
        } center: {
            Text("그림을 그려주세요")
        } trailing: {
            NextToolbarButton {
                viewModel.updateBodyImage()
                router.push(.pixelCustomizing)
            }
            .frame(width: 44, height: 44)
            .offset(x: -4)
        }
    }
}
