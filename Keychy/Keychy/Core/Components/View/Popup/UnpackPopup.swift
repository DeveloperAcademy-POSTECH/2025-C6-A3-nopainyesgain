//
//  UnpackPopup.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

struct UnpackPopup: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // 아이콘
            Image(.unpack)
                .resizable()
                .frame(width: 57, height: 54)
                .padding(.top, 14)
            
            // 제목
            Text("포장을 해제하시겠어요?")
                .typography(.suit20B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
            
            // 메시지
            Text("키링이 다시 내 보관함에서 활성화돼요.")
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

struct UnpackCompletePopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Image(.unpacked)
                .resizable()
                .frame(width: 210, height: 110)
                .padding(.vertical, 7)
                .padding(.top, 20)
            
            Text("선물 포장을 풀었습니다.")
                .typography(.suit17SB)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 220)
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
