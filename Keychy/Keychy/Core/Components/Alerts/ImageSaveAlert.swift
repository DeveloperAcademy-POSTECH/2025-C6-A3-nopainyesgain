//
//  ImageSavedAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/5/25.
//

import SwiftUI

/// 키링 이미지 저장 완료 Alert
struct ImageSaveAlert: View {
    let checkmarkScale: CGFloat
    
    var body: some View {
        VStack(spacing: 15) {
            Image("imageSave")
                .resizable()
                .frame(width: 161, height: 102)
                .padding(.top, 20)
            
            Text("이미지가 저장되었습니다.")
                .typography(.suit17SB)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 214)
        .transition(.scale.combined(with: .opacity))
        .scaleEffect(checkmarkScale)
    }
}
