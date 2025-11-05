//
//  CarabinerSelectItemTile.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI
import NukeUI

struct CarabinerItemTile: View {
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
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                
                // 유료 재화 표시
                VStack {
                    HStack {
                        if !carabiner.carabiner.isFree {
                            Image(.deselectPaid)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .padding(.top, 7)
                                .padding(.leading, 10)
                        }
                        Spacer()
                        // 보유 카라비너 표시
                        if carabiner.isOwned {
                            Text("보유")
                                .typography(.suit13SB)
                                .foregroundStyle(Color.white100)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(
                                    UnevenRoundedRectangle(bottomLeadingRadius: 5, topTrailingRadius: 10)
                                        .fill(Color.black60)
                                )
                            // 텍스트가 아주 조금 띄워져 보여져서 음수 오프셋을 사용합니다
                                .offset(y: -1)
                        }
                    }
                }
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black100.opacity(0.15))
                }
            } //: ZSTACK
            .frame(width: 140, height: 140)
            Text(carabiner.carabiner.carabinerName)
                .typography(.suit14SB18)
                .foregroundStyle(.black100)
        }
    }
}
