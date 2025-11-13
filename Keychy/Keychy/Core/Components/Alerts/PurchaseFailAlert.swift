//
//  PurchaseFailAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/5/25.
//

import SwiftUI

struct PurchaseFailAlert: View {

    let checkmarkScale: CGFloat
    let onCancel: () -> Void
    let onCharge: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                Image("bangMark")
                    .padding(.vertical, 4)

                Text("코인이 부족해요")
                    .typography(.suit20B)
                    .foregroundStyle(.black100)
                    .fixedSize(horizontal: true, vertical: false)

                Text("충전하러 갈까요?")
                    .typography(.suit17SB)
                    .foregroundStyle(.black100)
            }
            .padding(8)
            .padding(.bottom, 16)

            /// 취소, 확인 버튼
            HStack(spacing: 16) {
                Button {
                    onCancel()
                } label: {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundStyle(.black100)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.black10)

                // 충전 버튼
                Button {
                    onCharge()
                } label: {
                    Text("확인")
                        .typography(.suit17B)
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.main500)
            }
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 26.0))
        .scaleEffect(checkmarkScale)
    }
}

