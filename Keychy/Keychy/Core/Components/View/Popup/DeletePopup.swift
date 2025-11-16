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
            Image("DeleteAlert")
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
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
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
        .frame(width: 300)
    }
}

struct DeleteCompletePopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Text("삭제 되었습니다.")
            .typography(.suit17SB)
            .foregroundColor(.black100)
            .frame(width: 300, height: 73)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            }
    }
}
