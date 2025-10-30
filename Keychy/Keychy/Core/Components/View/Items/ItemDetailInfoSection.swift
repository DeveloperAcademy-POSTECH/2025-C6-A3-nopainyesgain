//
//  PreviewInfoSection.swift
//  Keychy
//
//  Created by 길지훈 on 10/28/25.
//

import SwiftUI

struct ItemDetailInfoSection: View {
    let item: any WorkshopItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            /// 태그들
            HStack(spacing: 8) {
                /// 유료 태그 표시
                if !item.isFree {
                    itemPaidTag
                }
                itemTags
            }
            .padding(.bottom, 4)

            /// item 이름
            itemName
                .padding(.bottom, 12)
            
            /// item 설명
            itemDescription
        }
    }

    
}

// MARK: - Components
extension ItemDetailInfoSection {
    private var itemTags: some View {
        HStack(spacing: 8) {
            if item.tags.isEmpty {
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
                ForEach(item.tags, id: \.self) { tag in
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

    private var itemPaidTag: some View {
        Image("PaidTestIcon")
    }

    private var itemName: some View {
        Text(item.name)
            .typography(.suit24B)
    }

    private var itemDescription: some View {
        Text(item.itemDescription)
            .typography(.suit15R)
            .foregroundStyle(.gray500)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ItemDetailInfoSection(item: KeyringTemplate.acrylicPhoto)
}



