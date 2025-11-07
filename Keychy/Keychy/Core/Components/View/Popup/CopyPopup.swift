//
//  CopyPopup.swift
//  Keychy
//
//  Created by Jini on 11/6/25.
//

import SwiftUI

struct CopyPopup: View {
    let myCopyPass: Int
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                // 제목
                Text("복사하기")
                    .typography(.suit20B)
                    .foregroundColor(.black100)
                    .padding(.top, 8)
                
                Image("myCopyPass")
                    .resizable()
                    .frame(width: 75, height: 45)
                
                Text("복사권을 사용하여\n키링을 복사합니다.")
                    .typography(.suit17SB)
                    .padding(.bottom, 5)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 6) {
                    Text("남은 복사권")
                        .typography(.suit15M25)
                    
                    Text("\(myCopyPass)")
                        .typography(.nanum16EB)
                        .foregroundColor(.main500)
                }
            }
            
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button(action: onCancel) {
                        Text("취소")
                            .typography(.suit17B)
                            .foregroundColor(.black100)
                            .frame(width: 76)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(.black10)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onConfirm) {
                        Text("복사하기")
                            .typography(.suit17B)
                            .foregroundColor(.white100)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(.black80)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 310)
    }
}

struct CopyCompletePopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Image("keyringCopy")
                .resizable()
                .frame(width: 127, height: 102)
                .padding(.vertical, 8)
            
            Text("키링이 복사되었어요!")
                .typography(.suit17SB)
                .foregroundColor(.black100)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(width: 300, height: 214)
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

#Preview {
    CopyCompletePopup(isPresented: .constant(true))
}
