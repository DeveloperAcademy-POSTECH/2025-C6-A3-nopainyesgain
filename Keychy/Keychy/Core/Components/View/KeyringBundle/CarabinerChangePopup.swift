//
//  CarabinerChangePopup.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI

struct CarabinerChangePopup: View {
    let title: String
    let message: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 12) {
                // 아이콘
                Image(.deleteAlert)
                    .resizable()
                    .frame(width: 57, height: 54)
                    .padding(.top, 8)
                
                // 제목
                Text(title)
                    .typography(.suit20B)
                    .foregroundColor(.black100)
                    .multilineTextAlignment(.center)
                
                // 메시지
                Text(message)
                    .typography(.suit15R)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
            
            // 버튼들
            HStack(spacing: 16) {
                // 취소 버튼
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
                
                // 확인 버튼
                Button(action: onConfirm) {
                    Text("확인")
                        .typography(.suit17B)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.pink100)
                        )
                }
                .buttonStyle(.plain)
            }
            
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
    }
}
