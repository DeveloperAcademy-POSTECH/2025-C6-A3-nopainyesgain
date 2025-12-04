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
            Image(.imageSaved)
        }
        .transition(.scale.combined(with: .opacity))
        .scaleEffect(checkmarkScale)
    }
}
