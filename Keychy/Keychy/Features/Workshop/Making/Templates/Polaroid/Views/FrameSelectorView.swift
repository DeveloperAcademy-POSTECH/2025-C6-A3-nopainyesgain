//
//  FrameSelectorView.swift
//  Keychy
//
//  폴라로이드 템플릿 프레임 선택 뷰 (하단 영역)
//

import SwiftUI
import NukeUI

struct FrameSelectorView: View {
    @Bindable var viewModel: PolaroidVM

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("프레임 선택")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 20)

            // 프레임 목록
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableFrames) { frame in
                        frameCell(frame: frame)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 94)

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
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 6) {
                    LazyImage(url: URL(string: frame.thumbnailURL)) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else if state.isLoading {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray100)
                                .frame(width: 70, height: 70)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 70, height: 70)
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

                // 체크 뱃지 (선택 시)
                if isSelected {
                    ZStack {
                        Circle()
                            .stroke(.white100)
                            .fill(.main500)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 0)
                            .frame(width: 20, height: 20)
                        Image(.recCheck)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.white100)
                    }
                    .padding(.bottom, 24)
                    .padding(.trailing, 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
