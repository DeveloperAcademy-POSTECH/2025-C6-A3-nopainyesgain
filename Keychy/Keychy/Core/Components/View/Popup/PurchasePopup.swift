//
//  PurchasePopup.swift
//  Keychy
//
//  Created by Jini on 11/5/25.
//

import SwiftUI

struct PurchasePopup: View {
    let title: String
    let myCoin: Int
    let price: Int
    let onConfirm: () -> Void
    
    
    var body: some View {
        VStack(spacing: 10) {
            // 제목
            Text(title)
                .typography(.suit20B)
                .foregroundColor(.black100)
                .padding(.top, 8)
            
            Text("구매하시겠어요?")
                .typography(.suit17SB)
                .padding(.bottom, 24)
            
            HStack(spacing: 6) {
                Text("내 보유")
                    .typography(.suit15M25)
                
                Text("\(myCoin)")
                    .typography(.nanum16EB)
                    .foregroundColor(.main500)
            }

            // 버튼
            Button(action: onConfirm) {
                HStack(spacing: 4) {
                    Image("buyKey")
                        .resizable()
                        .frame(width: 34, height: 34)
                        .padding(.bottom, 4)
                    
                    Text("\(price)")
                        .typography(.nanum18EB)
                        .foregroundColor(.white100)
                        .frame(height: 32)
                        .padding(.top, 4)
 
                }

            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(.black80)
            )
            .buttonStyle(.plain)
            
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 207)
    }
}

#Preview {
    PurchasePopup(title: "인벤토리 확장", myCoin: 3100, price: 100, onConfirm: {})
}
