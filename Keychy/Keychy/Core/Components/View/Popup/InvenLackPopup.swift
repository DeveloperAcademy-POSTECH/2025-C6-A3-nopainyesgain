//
//  InvenLackPopup.swift
//  Keychy
//
//  Created by Jini on 11/9/25.
//

import SwiftUI

struct InvenLackPopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // 아이콘
            Image(.bangMark)
                .resizable()
                .frame(width: 57, height: 54)
                .padding(.vertical, 4)
                .padding(.top, 8)
            
            // 제목
            Text("보관함이 가득 찼어요.")
                .typography(.suit20B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            // 메시지
            Text("새로운 키링을 추가하려면\n보관함을 비우거나 확장해주세요.")
                .typography(.suit17SB)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
        }
    }
}
