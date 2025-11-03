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

                /// 이펙트 타입 표시 (사운드/파티클)
                if let effectType = effectTypeTag {
                    tagView(text: effectType.rawValue)
                } else {
                    // 이펙트가 아닐 경우에만 일반 태그 표시
                    itemTags
                }
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
    /// 이펙트 타입 태그 (사운드/파티클)
    private var effectTypeTag: EffectFilterType? {
        if item is Sound {
            return .sound
        } else if item is Particle {
            return .particle
        }
        return nil
    }

    /// 태그 뷰 생성
    private func tagView(text: String) -> some View {
        Text(text)
            .typography(.suit14M)
            .foregroundStyle(.gray500)
            .multilineTextAlignment(.center)
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(.gray50)
            .clipShape(.rect)
            .cornerRadius(10)
    }

    private var itemTags: some View {
        HStack(spacing: 8) {
            ForEach(item.tags, id: \.self) { tag in
                tagView(text: tag)
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



