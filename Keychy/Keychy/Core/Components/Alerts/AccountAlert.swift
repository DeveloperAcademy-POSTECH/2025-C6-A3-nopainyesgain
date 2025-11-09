//
//  AccountAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/9/25.
//

import SwiftUI

struct AccountAlert: View {
    let checkmarkScale: CGFloat
    let title: String
    let text: String
    let cancelText: String
    let confirmText: String
    let confirmBtnColor: Color
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 23) {
            VStack(spacing: 10) {
                
                Text(title)
                    .typography(.suit20B)
                    .foregroundStyle(.black100)
                
                Text(text)
                    .typography(.suit17SB)
                    .multilineTextAlignment(.center)
                
            }
            .padding(8)
            
            // 버튼 영역
            HStack(spacing: 16) {
                Button {
                    onCancel()
                } label: {
                    Text(cancelText)
                        .typography(.suit17B)
                        .foregroundStyle(.black100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.gray200)
                
                Button {
                    onConfirm()
                } label: {
                    Text(confirmText)
                        .typography(.suit17B)
                        .foregroundStyle(.white100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(confirmBtnColor)
            }
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 40))
        .frame(minWidth: 200)
        .scaleEffect(checkmarkScale)
    }
}
