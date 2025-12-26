//
//  NoInternetView.swift
//  Keychy
//
//  Created on 12/25/24.
//

import SwiftUI

/// 네트워크 연결 없음 전체 화면 에러 뷰
struct NoInternetView: View {
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 아이콘
            Image(.noInternetBangMark)
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(.main500)
                .padding(.bottom, 25)

            // 제목
            Text("화면을 불러올 수 없어요")
                .typography(.suit18SB)
                .foregroundStyle(.black)
                .padding(.bottom, 10)

            // 설명
            Text("네트워크 연결 상태를 확인하고\n잠시 후 다시 시도해주세요.")
                .typography(.suit15R)
                .foregroundStyle(.black100)
                .multilineTextAlignment(.center)
                .padding(.bottom, 25)

            // 다시 시도 버튼
            Button {
                onRetry()
            } label: {
                Text("다시 시도")
                    .typography(.suit17B)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13.5)
                    .foregroundStyle(.black)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    NoInternetView {
        print("Retry tapped")
    }
    .background(.white70)
}
