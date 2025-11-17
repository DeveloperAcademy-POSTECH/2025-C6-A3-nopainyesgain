//
//  CarabinerSelectItemTile.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI
import NukeUI

struct SelectCarabinerGridItem: View {
    var isSelected: Bool
    var carabiner: CarabinerViewData

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
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .frame(width: threeSquareGridCellSize, height: threeSquareGridCellSize)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white100))
                
                // 유료 재화 표시
                VStack {
                    HStack {
                        if !carabiner.carabiner.isFree {
                            HStack {
                                Image(.paidIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32)
                            }
                        }
                        
                        Spacer()
                        // 보유 카라비너 표시
                        if carabiner.isOwned {
                            Text("보유")
                                .typography(.suit13M)
                                .foregroundStyle(.white100)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.top, 3)
                    .padding(.horizontal, 7)
                    
                    Spacer()
                }
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black100.opacity(0.15))
                }
            } //: ZSTACK
            .clipped()
            Text(carabiner.carabiner.carabinerName)
                .typography(isSelected ? .notosans14SB : .notosans14M)
                .foregroundStyle(isSelected ? .main500 : .black100)
        }
    }
}
