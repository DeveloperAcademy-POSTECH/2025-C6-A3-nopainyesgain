//
//  DrawingToolsView.swift
//  Keychy
//
//  네온사인 템플릿 전용 그리기 도구 뷰
//

import SwiftUI

struct DrawingToolsView: View {
    @Bindable var viewModel: NeonSignVM

    let colors: [Color] = [.white, .red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 색상 선택
            colorSelector

            // 선 굵기 조절
            lineWidthSelector

            // 실행 취소 버튼
            undoButton

            Spacer()
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
            .fill(.white100)
            .shadow(color: .black.opacity(0.15), radius: 9)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Color Selector

    private var colorSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("색상")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 30)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            viewModel.currentDrawingColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            viewModel.currentDrawingColor == color ? .black : .gray300,
                                            lineWidth: viewModel.currentDrawingColor == color ? 3 : 1
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Line Width Selector

    private var lineWidthSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("선 굵기")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)

                Spacer()

                Text("\(Int(viewModel.currentLineWidth))pt")
                    .typography(.suit14M)
                    .foregroundStyle(.gray500)
            }
            .padding(.horizontal, 20)

            Slider(value: $viewModel.currentLineWidth, in: 1...20, step: 1)
                .tint(.main500)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Undo Button

    private var undoButton: some View {
        Button {
            if !viewModel.drawingPaths.isEmpty {
                viewModel.drawingPaths.removeLast()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.backward")
                Text("실행 취소")
            }
            .typography(.suit15SB25)
            .foregroundStyle(viewModel.drawingPaths.isEmpty ? .gray400 : .black100)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.drawingPaths.isEmpty ? .gray100 : .gray50)
            )
        }
        .disabled(viewModel.drawingPaths.isEmpty)
        .padding(.horizontal, 20)
    }
}
