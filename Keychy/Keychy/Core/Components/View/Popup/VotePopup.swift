//
//  VotePopup.swift
//  Keychy
//
//  Created by Jini on 11/24/25.
//

import SwiftUI

struct VotePopup: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // 아이콘
            Image("bangMark")
                .resizable()
                .frame(width: 57, height: 54)
                .padding(.top, 14)
            
            // 제목
            Text("이 키링에 투표하시겠어요?")
                .typography(.suit20B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
            
            // 메시지
            Text("투표는 취소할 수 없어요.")
                .typography(.suit15R)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
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
                                .fill(.main500)
                        )
                }
                .buttonStyle(.plain)
            }
            
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300)
    }
}
