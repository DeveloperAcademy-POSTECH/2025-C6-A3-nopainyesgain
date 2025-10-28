//
//  PreviewMakingBtn.swift
//  Keychy
//
//  Created by 길지훈 on 10/28/25.
//

import SwiftUI

struct PreviewMakingBtn: View {
    let title: String
    
    // 클로저로 액션 전달 받기
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .typography(.suit17B)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(.main500)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PreviewMakingBtn(title: "예시버튼", action: { print("예시동작") })
}
