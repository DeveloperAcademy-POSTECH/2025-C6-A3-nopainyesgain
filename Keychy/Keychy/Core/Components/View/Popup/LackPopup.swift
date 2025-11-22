//
//  LackPopup.swift
//  Keychy
//
//  Created by Jini on 11/6/25.
//

import SwiftUI

struct LackPopup: View {
    let title: String
    var message: String = "충전하러 갈까요?"
    var onCancel: (() -> Void)? = nil
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            // 아이콘
            Image("bangMark")
                .resizable()
                .frame(width: 57, height: 54)
                .padding(.top, 14)

            // 제목
            Text(title) // ~~가 부족합니다!
                .typography(.suit20B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)

            // 메시지
            Text(message)
                .typography(.suit17SB)
                .padding(.bottom, 24)

            // 버튼들
            HStack(spacing: 16) {
                // 취소 버튼 (onCancel이 있을 때만 표시)
                if let onCancel = onCancel {
                    Button(action: onCancel) {
                        Text("취소")
                            .typography(.suit17SB)
                            .foregroundColor(.black100)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(.black10)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // 확인 버튼
                Button(action: onConfirm) {
                    Text("확인")
                        .typography(.suit17B)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.main500)
                        )
                }
                .buttonStyle(.plain)
            }

        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 246)
    }
}
