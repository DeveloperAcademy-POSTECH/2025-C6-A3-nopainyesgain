//
//  NoInternetToast.swift
//  Keychy
//
//  Created on 12/25/24.
//

import SwiftUI

/// 네트워크 연결 상태 토스트 알림
struct NoInternetToast: View {
    var body: some View {
        HStack(spacing: 10) {
            // 아이콘
            Image(.noInternetToastMark)

            // 메시지
            Text("연결 상태를 다시 확인해주세요")
                .typography(.suit15B)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 46.15)
        .padding(.vertical, 18)
        .background(.black70)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        NoInternetToast()
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.3))
}
