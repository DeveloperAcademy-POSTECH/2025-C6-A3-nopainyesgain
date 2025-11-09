//
//  PerchaseSuccessAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/5/25.
//

import SwiftUI

struct PurchaseSuccessAlert: View {
    let checkmarkScale: CGFloat
    
    var body: some View {
        VStack(spacing: 23) {
            Image("checkmarker")
            
            Text("구매가 완료되었습니다.")
                .typography(.suit17SB)
        }
        .padding(.top, 32)
        .padding(.horizontal, 22)
        .padding(.bottom, 26)
        .glassEffect(in: .rect(cornerRadius: 15))
        .frame(width: 300, height: 214)
        .scaleEffect(checkmarkScale)
    }
}
