//
//  LoadingAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/5/25.
//

import SwiftUI

struct LoadingAlert: View {
    let checkmarkScale: CGFloat
    
    var body: some View {
        VStack(spacing: 23) {
            Image("appIcon")
                .resizable()
                .frame(width: 80, height: 80)
            
            Text("잠시만 기다려주세요. . .")
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
