//
//  PreviewInfoSection.swift
//  Keychy
//
//  Created by 길지훈 on 10/28/25.
//

import SwiftUI

struct PreviewInfoSection: View {
    let template: KeyringTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            /// 태그들
            HStack(spacing: 8) {
                /// 유료 태그 표시
                if !template.isFree {
                    templatePaidTag
                }
                templateTags
            }
            .padding(.bottom, 4)

            /// 템플릿 이름
            templateName
                .padding(.bottom, 12)
            
            /// 템플릿 설명
            templateDescription
        }
    }

    
}

// MARK: - Components
extension PreviewInfoSection {
    private var templateTags: some View {
        HStack(spacing: 8) {
            if template.tags.isEmpty {
                Text("지정된 태그가 없습니다.")
                    .typography(.suit14M)
                    .foregroundStyle(.gray500)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(.gray50)
                    .clipShape(.rect)
                    .cornerRadius(10)
            } else {
                ForEach(template.tags, id: \.self) { tag in
                    Text(tag)
                        .typography(.suit14M)
                        .foregroundStyle(.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(.gray50)
                        .clipShape(.rect)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var templatePaidTag: some View {
        Image("PaidTestIcon")
    }

    private var templateName: some View {
        Text(template.templateName)
            .typography(.suit24B)
    }

    private var templateDescription: some View {
        Text(template.description)
            .typography(.suit15R)
            .foregroundStyle(.gray500)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PreviewInfoSection(template: .acrylicPhoto)
}



