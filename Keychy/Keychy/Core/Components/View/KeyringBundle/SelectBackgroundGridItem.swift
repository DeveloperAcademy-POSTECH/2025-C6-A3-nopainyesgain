//
//  SelectBackgroundGridItem.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI
import NukeUI

struct SelectBackgroundGridItem: View {
    let background: BackgroundViewData
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // 배경 이미지
                LazyImage(url: URL(string: background.background.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if state.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(2/3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Color.gray.opacity(0.1)
                            .aspectRatio(2/3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                // 오버레이 요소들
                VStack {
                    HStack {
                        // 유료 배경은 유료 아이콘 표시
                        if !background.background.isFree {
                            Image(.deselectPaid)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .padding(EdgeInsets(top: 7, leading: 10, bottom: 0, trailing: 0))
                        }
                        Spacer()
                        //소유하고 있는 배경화면은 보유 표시
                        if background.isOwned {
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
                    .padding(.all, 0)
                    Spacer()
                }
                .padding(.all, 0)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
            )

            Text(background.background.backgroundName)
                .typography(.suit14SB18)
                .foregroundStyle(.black100)
        } //:VSTACK
    }
}
