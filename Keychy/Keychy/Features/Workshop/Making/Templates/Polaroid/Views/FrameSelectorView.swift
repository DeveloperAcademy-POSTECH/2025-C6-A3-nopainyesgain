//
//  FrameSelectorView.swift
//  Keychy
//
//  폴라로이드 템플릿 프레임 선택 뷰 (하단 영역)
//

import SwiftUI

struct FrameSelectorView: View {
    @Bindable var viewModel: PolaroidVM

    // 임시 프레임 목록
    let frames = ["Frame1", "Frame2", "Frame3", "Frame4"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("프레임 선택")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 30)
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
