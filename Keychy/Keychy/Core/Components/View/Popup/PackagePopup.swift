//
//  PackagePopup.swift
//  Keychy
//
//  Created by Jini on 11/8/25.
//

import SwiftUI

struct PackagePopup: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 아이콘
            Image("PresentImg")
                .resizable()
                .frame(width: 61, height: 72)
                .padding(.top, 8)
            
            // 제목
            Text("키링을 포장할까요?")
                .typography(.suit20B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
            
            // 메시지
            Text("포장하면 선물 링크가 만들어집니다.\n보관함과 뭉치에 있는 키링이 비활성화돼요.")
                .typography(.suit15R)
                .multilineTextAlignment(.center)
            
            Text("수락 시 상대방의 보관함으로 이동합니다.\n포장은 언제든 직접 풀 수 있어요.")
                .typography(.suit15R)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
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
        .frame(width: 300, height: 321)
    }
}

struct PackingPopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
//        Text("키링 포장 중...")
//            .typography(.suit17SB)
//            .foregroundColor(.black100)
//            .frame(width: 300, height: 94)
//            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
//            .transition(.scale.combined(with: .opacity))

        VStack(spacing: 19) {
            Image("WalkingPresent") // 네이밍 미안합니다
                .resizable()
                .frame(width: 128, height: 191)
            
            Text("포장 중...")
                .typography(.suit17SB)
                .foregroundColor(.white100)
        }
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
