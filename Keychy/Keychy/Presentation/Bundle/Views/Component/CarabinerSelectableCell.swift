//
//  CarabinerSelectItemTile.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI
import NukeUI

struct CarabinerSelectableCell: View {
    var carabiner: CarabinerViewData
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                // 카라비너 이미지
                LazyImage(url: URL(string: carabiner.carabiner.carabinerImage[0])) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .clipped()
                    } else if state.isLoading {
                        LoadingAlert(type: .short, message: nil)
                            .scaleEffect(0.5)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(3.55)
                .frame(width: threeSquareGridCellSize, height: threeSquareGridCellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? .mainOpacity80 : .clear, lineWidth: 1.8)
                    
                )
                
                // 유료 재화 표시
                VStack {
                    HStack {
                        // 유료 아이콘
                        Image(.paidIcon)
                            .padding(.top, 3)
                            .opacity(carabiner.carabiner.isFree ? 0 : 1)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 3)
                .padding(.leading, 7)
                
                VStack {
                    HStack {
                        Spacer()
                        Text("보유")
                            .typography(.suit13M)
                            .foregroundStyle(.white100)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .opacity((carabiner.isOwned && !carabiner.carabiner.isFree) ? 1 : 0)
                    }
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.trailing, 7)
            } //: ZSTACK
            .clipped()
            Text(carabiner.carabiner.carabinerName)
                .typography(isSelected ? .notosans14SB : .notosans14M)
                .foregroundStyle(isSelected ? .main500 : .black100)
        }
    }
}
