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
        VStack(spacing: 5) {
            Image(.checkmarker2)
            
            Text("구매가 완료되었어요!")
                .typography(.suit17SB)
        }
        .padding(.top, 15)
        .padding(.horizontal, 8)
        .padding(.bottom, 40)
        .glassEffect(in: .rect(cornerRadius: 26.0))
        .scaleEffect(checkmarkScale)
    }
}
