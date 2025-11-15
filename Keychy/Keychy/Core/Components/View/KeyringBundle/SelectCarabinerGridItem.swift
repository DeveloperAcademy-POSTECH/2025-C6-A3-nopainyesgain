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
    var widthSize: CGFloat
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
                            .frame(width: (widthSize - 60) / 3, height: (widthSize - 60) / 3)
                    } else if state.isLoading {
                        ProgressView()
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
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
                            .padding(.top, 7)
                            .padding(.leading, 10)
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
                    .padding(.horizontal, 5)
                    .padding(.top, 3)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        // 다운로드 표시
                        if carabiner.carabiner.isFree && !carabiner.isOwned {
                            Image(.download)
                                .resizable()
                                .frame(width: 18, height: 18)
                                .padding(7)
                        }
                    }
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
