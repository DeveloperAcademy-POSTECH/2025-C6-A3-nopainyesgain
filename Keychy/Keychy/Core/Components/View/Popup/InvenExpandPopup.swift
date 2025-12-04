//
//  InvenExpandPopup.swift
//  Keychy
//
//  Created by Jini on 11/16/25.
//

import SwiftUI

struct InvenExpandPopup: View {
    let myCoin: Int
    let price: Int
    let onCancel: () -> Void
    let onConfirm: () -> Void


    var body: some View {
        VStack(spacing: 0) {
            // 제목
            VStack(spacing: 20) {
                Text("보관함 확장")
                    .typography(.suit20B)
                    .foregroundColor(.black100)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                
                Image(.expandIcon)
                    .resizable()
                    .frame(width: 111, height: 70)
                    .padding(.vertical, 8)

                Text("보관함을 확장할까요? (+10)")
                    .typography(.suit17SB)
                    .padding(.bottom, 15)
            }
            .padding(.bottom, 10)

            HStack(spacing: 4) {
                Text("내 보유")
                    .typography(.suit15M25)
                    .foregroundColor(.black100)

                Text("\(myCoin)")
                    .typography(.nanum16EB)
                    .foregroundColor(.main500)
            }
            .padding(.bottom, 6)

            // 버튼
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
                    HStack(spacing: 4) {
                        Image(.buyKey)
                            .resizable()
                            .frame(width: 34, height: 34)
                            .padding(.bottom, 4)
                        
                        Text("\(price)")
                            .typography(.nanum18EB)
                            .foregroundColor(.white100)
                            .frame(height: 32)
                            .padding(.top, 4)
     
                    }
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
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300)
    }
}
