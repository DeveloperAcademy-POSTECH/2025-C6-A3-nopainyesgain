//
//  DrawingCanvasView.swift
//  Keychy
//
//  네온사인 템플릿 전용 그리기 캔버스 뷰
//

import SwiftUI

struct DrawingCanvasView: View {
    @Bindable var viewModel: NeonSignVM

    @State private var currentPath = Path()
    @State private var imageFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경
                Color.white100

                // 네온사인 바디 이미지 (그리기 가능 영역)
                if let bodyImage = viewModel.bodyImage {
                    Image(uiImage: bodyImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .background(
                            GeometryReader { imageGeometry in
                                Color.clear
                                    .preference(key: ImageFramePreferenceKey.self,
                                              value: imageGeometry.frame(in: .named("canvasSpace")))
                            }
                        )
                        .onPreferenceChange(ImageFramePreferenceKey.self) { frame in
                            imageFrame = frame
                            viewModel.imageFrame = frame  // ViewModel에도 저장
                        }
                }

                // 그리기 캔버스 (이미지 위에만 그려짐)
                Canvas { context, size in
                    // 저장된 경로들 그리기
                    for drawnPath in viewModel.drawingPaths {
                        var path = drawnPath.path
                        context.stroke(
                            path,
                            with: .color(drawnPath.color),
                            lineWidth: drawnPath.lineWidth
                        )
                    }

                    // 현재 그리는 경로
                    context.stroke(
                        currentPath,
                        with: .color(viewModel.currentDrawingColor),
                        lineWidth: viewModel.currentLineWidth
                    )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = value.location

                            // bodyImage 영역 내에서만 그리기 허용
                            guard imageFrame.contains(point) else { return }

                            if currentPath.isEmpty {
                                currentPath.move(to: point)
                            } else {
                                currentPath.addLine(to: point)
                            }
                        }
                        .onEnded { _ in
                            // 경로가 비어있지 않으면 저장
                            if !currentPath.isEmpty {
                                viewModel.drawingPaths.append(DrawnPath(
                                    path: currentPath,
                                    color: viewModel.currentDrawingColor,
                                    lineWidth: viewModel.currentLineWidth
                                ))
                                currentPath = Path()
                            }
                        }
                )
            }
            .coordinateSpace(name: "canvasSpace")
        }
    }
}

// MARK: - Drawing Data Model
struct DrawnPath: Identifiable {
    let id = UUID()
    let path: Path
    let color: Color
    let lineWidth: CGFloat
}

// MARK: - Preference Key for Image Frame
struct ImageFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
