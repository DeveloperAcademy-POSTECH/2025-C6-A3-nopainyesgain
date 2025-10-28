//
//  PreviewInfoSection.swift
//  Keychy
//
//  Created by 길지훈 on 10/28/25.
//

import SwiftUI

struct PreviewInfoSection: View {
    var body: some View {
        templateInfo
    }
    
    private var templateInfo: some View {
        VStack(alignment: .leading, spacing: 0) {
            templateTag
                .padding(.bottom, 4)
            templateName
                .padding(.bottom, 12)
            templateDescription
        }
    }
    
    // TODO: - 유료키링 표시 -> 로직 필요
    private var templatePrice: some View {
        Text("")
    }
    
    // TODO: - 키링 분류 태그 -> 로직 필요
    private var templateTag: some View {
        Text("카테고리")
            .typography(.suit14M)
            .foregroundStyle(.gray500)
            .multilineTextAlignment(.center)
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(.gray50)
            .clipShape(.rect)
            .cornerRadius(10)
        
    }
    
    private var templateName: some View {
        Text("아이템 이름")
            .typography(.suit24B)
    }
    
    // TODO: - 키링 설명 태그 -> 로직 필요
    private var templateDescription: some View {
        Text("유료 아이콘 표시(유료 아이템만), 카테고리 표시, 보유중 표시, 사운드는 버튼 활성화")
            .typography(.suit15R)
            .foregroundStyle(.gray500)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PreviewInfoSection()
}



