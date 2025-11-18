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

    var body: some View {
        ZStack {
            // 그리기 캔버스
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
                        if currentPath.isEmpty {
                            currentPath.move(to: point)
                        } else {
                            currentPath.addLine(to: point)
                        }
                    }
                    .onEnded { _ in
                        // 현재 경로를 저장
                        viewModel.drawingPaths.append(DrawnPath(
                            path: currentPath,
                            color: viewModel.currentDrawingColor,
                            lineWidth: viewModel.currentLineWidth
                        ))
                        currentPath = Path()
                    }
            )

            // 네온사인 바디 이미지 오버레이
            if let bodyImage = viewModel.bodyImage {
                Image(uiImage: bodyImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .allowsHitTesting(false) // 터치 이벤트 무시
            }
        }
        .background(.gray100)
    }
}

// MARK: - Drawing Data Model
struct DrawnPath: Identifiable {
    let id = UUID()
    let path: Path
    let color: Color
    let lineWidth: CGFloat
}
