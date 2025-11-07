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
        VStack(spacing: 23) {
            Image("imageSave")
            
            Text("이미지가 저장되었습니다.")
                .typography(.suit17SB)
        }
        .padding(.top, 32)
        .padding(.horizontal, 22)
        .padding(.bottom, 26)
        .glassEffect(in: .rect(cornerRadius: 15))
        .frame(minWidth: 300)
        .scaleEffect(checkmarkScale)
    }
}
