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
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // 배경 이미지
                LazyImage(url: URL(string: background.background.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .aspectRatio(5/7, contentMode: .fit)
                    } else if state.isLoading {
                        ProgressView()
                            .aspectRatio(5/7, contentMode: .fit)
                    }
                }
                .scaledToFit()
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? .black.opacity(0.15) : .clear)
                    
                )
                VStack {
                    HStack {
                        // 유료 아이콘
                        if !background.background.isFree {
                            Image(.keyHole)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .padding(.top, 3)
                        }
                        
                        Spacer()
                        // 보유 표시
                        if background.isOwned {
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
                        // 다운로드 아이콘
                        if background.background.isFree && !background.isOwned {
                            Image(.download)
                                .resizable()
                                .frame(width: 18, height: 18)
                                .padding(7)
                        }
                    }
                }
            }
            // 이름 라벨
            Text(background.background.backgroundName)
                .typography(isSelected ? .notosans14SB : .notosans14M)
                .foregroundStyle(isSelected ? .main500 : .black100)
        } //: VSTACK
    }
}
