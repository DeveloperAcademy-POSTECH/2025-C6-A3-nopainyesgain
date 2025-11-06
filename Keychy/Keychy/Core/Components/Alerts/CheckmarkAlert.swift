//
//  CheckmarkAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/5/25.
//

import SwiftUI

struct CheckmarkAlert: View {
    
    let checkmarkScale: CGFloat
    let text: String
    
    var body: some View {
        VStack(spacing: 23) {
            Image("checkmarker")
            
            Text(text)
                .typography(.suit17SB)
        }
        .padding(.top, 42)
        .padding(.horizontal, 55)
        .padding(.bottom, 26)
        .glassEffect(in: .rect(cornerRadius: 15))
        .frame(minWidth: 300)
        .scaleEffect(checkmarkScale)
    }
}
