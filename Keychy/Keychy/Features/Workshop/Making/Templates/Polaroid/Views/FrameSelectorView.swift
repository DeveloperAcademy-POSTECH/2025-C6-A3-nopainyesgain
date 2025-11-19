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
                        Button {
                            viewModel.selectedFrame = frame
                        } label: {
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
                                        viewModel.selectedFrame?.id == frame.id ? Color.main500 : Color.clear,
                                        lineWidth: 2.5
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 70)

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
}
