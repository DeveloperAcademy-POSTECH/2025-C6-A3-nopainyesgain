//
//  DeletePopup.swift
//  Keychy
//
//  Created by Jini on 11/4/25.
//

import SwiftUI

struct DeletePopup: View {
    let title: String
    let message: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 아이콘
            Image("AlertImage")
                .resizable()
                .frame(width: 57, height: 54)
                .padding(.top, 12)
            
            // 제목
            Text(title)
                .typography(.suit20B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
            
            // 메시지
            Text(message)
                .typography(.suit17SB)
                .padding(.bottom, 22)
            
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
                                .fill(.secondaryLightGray)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 확인 버튼
                Button(action: onConfirm) {
                    Text("확인")
                        .typography(.suit17B)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color(red: 1.0, green: 0.2, blue: 0.4))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 34))
        .glassEffect(in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 278)
    }
}

#Preview {
    DeletePopup(title: "[태그 1]\n정말 삭제하시겠어요?", message: "한 번 삭제하면 복구 할 수 없습니다.", onCancel: {}, onConfirm: {})
}
