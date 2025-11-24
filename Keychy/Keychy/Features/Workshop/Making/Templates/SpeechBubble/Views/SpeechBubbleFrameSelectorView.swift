//
//  SpeechBubbleFrameSelectorView.swift
//  Keychy
//
//  Created by 길지훈 on 11/24/25.
//
//  말풍선 템플릿 프레임 선택 뷰 (하단 영역)
//

import SwiftUI
import NukeUI

struct SpeechBubbleFrameSelectorView: View {
    @Bindable var viewModel: SpeechBubbleVM

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - 프레임 섹션
            Text("프레임")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableFrames) { frame in
                        frameCell(frame: frame)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 94)

            // MARK: - 컬러 섹션
            VStack(alignment: .leading, spacing: 2) {
                Text("컬러")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)
                    .padding(.leading, 20)

                ColorPalette(selectedColor: $viewModel.selectedTextColor)
                    .padding(.leading, 16)
            }

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

    // MARK: - Frame Cell

    @ViewBuilder
    private func frameCell(frame: Frame) -> some View {
        let isSelected = viewModel.selectedFrame?.id == frame.id

        Button {
            viewModel.selectedFrame = frame
        } label: {
            VStack(spacing: 6) {
                LazyImage(url: URL(string: frame.thumbnailURL)) { state in
                    if let image = state.image {
                        ZStack {
                            Color.gray50

                            image
                                .resizable()
                                .scaledToFit()
                                .padding(.vertical, 8)
                        }
                        .frame(width: 105, height: 105)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray100)
                            .frame(width: 105, height: 105)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.main500 : Color.clear,
                            lineWidth: 2.5
                        )
                )

                // 프레임 이름
                Text(frame.name)
                    .typography(isSelected ? .notosans12SB : .notosans12M)
                    .foregroundStyle(isSelected ? .main500 : .black100)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 70)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SpeechBubbleFrameSelectorView(viewModel: SpeechBubbleVM())
}
