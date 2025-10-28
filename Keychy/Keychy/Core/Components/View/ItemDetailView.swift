//
//  ItemDetailView.swift
//  Keychy
//
//  Created by 김서현 on 10/28/25.
//

import SwiftUI

/// 배경화면, 키링, 사운드 등의 아이템의 상세보기 화면입니다. 유료 아이템은 재화 사용으로 이어집니다.
/// - itemType: 배경화면, 키링, 사운드 분류
/// - itemImage : 아이템 미리보기 사진
/// - itemName: 아이템 이름
/// - itemCategory: 아이템 카테고리 (카테고리 사운드이면 재생 버튼 활성화)
/// - itemDescription : 아이템 상세 설명
/// - itemPrice: 아이템 가격 (itemPrice > 0이면 유료 재화로 판단함)
struct ItemDetailView: View {
    var itemType: itemType
    var itemImage: String
    var itemName: String
    var itemCategory: String
    var itemDescription: String
    var itemPrice: Int
    
    var imageAspectRatio: CGFloat {
        switch itemType {
        case .keyring:
            3/4
        case .background:
            16/9
        case .effect:
            1/1
        case .sound:
            1/1
        }
    }
    
    var body: some View {
        VStack {
            ItemImageSection
                .padding(.horizontal, 60)
            ItemInfoSection
                .padding(.horizontal, 30)
            Button {
                // action
            } label: {
                Text("만들기")
                    .typography(.suit17B)
                    .padding(.vertical, 7.5)
                    .foregroundStyle(.white100)
                    .background(
                        RoundedRectangle(cornerRadius: 1000)
                            .fill(.main500)
                            .frame(maxWidth: .infinity)
                    )
            }
            .padding(.horizontal, 34)
        }
    }
}
/// 미리보기 이미지 화면
extension ItemDetailView {
    private var ItemImageSection: some View {
        Image(itemImage)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(imageAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .background(.gray300)
    }
}

/// 아이템 정보 표시 화면
/// - 유료 표시, 카테고리 표시, 아이템 이름, 아이템 설명
extension ItemDetailView {
    private var ItemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0.96) {
                    //유료 재화 아이콘 표시
                    if itemPrice > 0 {
                        Image(.cherries)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }
                    // 키링인 경우에만 카테고리 띄움
                    if itemType == .keyring {
                        Text(itemCategory)
                            .typography(.suit14M)
                            .foregroundStyle(Color.gray500)
                            .padding(.vertical, 5)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.gray50)
                            )
                    }
                }
                
                HStack {
                    // 아이템 이름
                    Text(itemName)
                        .typography(.suit24B)
                        .foregroundStyle(.black100)
                    //TODO: - 아이템 보유/미보유 상태 표시 띄우기
                    
                }
            }
            HStack {
                Text(itemDescription)
                    .multilineTextAlignment(.leading)
                    .typography(.suit15R)
                    .foregroundStyle(.gray500)
                Spacer()
                if itemType == .sound {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black100)
                        .overlay(
                            Image(systemName: "play.fill")
                                .foregroundStyle(.white100)
                                .padding(10.65)
                        )
                }
            }
        }
    }
}

enum itemType {
    case keyring
    case background
    case sound
    case effect
}

#Preview {
    ItemDetailView(
        itemType: .background,
        itemImage: "ddochi",
        itemName: "또치 키링",
        itemCategory: "배경화면",
        itemDescription: "유료 아이콘 표시, 카테고리 표시, 보유중 표시, 사운드는 버튼 활성화",
        itemPrice: 500
    )
}
