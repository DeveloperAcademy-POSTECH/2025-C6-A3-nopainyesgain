//
//  BangmarkAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/7/25.
//

import SwiftUI

struct BangmarkAlert: View {
    let checkmarkScale: CGFloat
    let text: String
    let cancelText: String
    let confirmText: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 23) {
            Image("bangMark")

            Text(text)
                .typography(.suit17SB)
                .multilineTextAlignment(.center)

            // 버튼 영역
            HStack(spacing: 12) {
                Button {
                    onCancel()
                } label: {
                    Text(cancelText)
                        .typography(.suit16B)
                        .foregroundStyle(.gray600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.gray200)

                Button {
                    onConfirm()
                } label: {
                    Text(confirmText)
                        .typography(.suit16B)
                        .foregroundStyle(.white100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.main500)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 42)
        .padding(.horizontal, 24)
        .padding(.bottom, 26)
        .glassEffect(in: .rect(cornerRadius: 40))
        .frame(minWidth: 200)
        .scaleEffect(checkmarkScale)
    }
}
