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
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                            .clipped()
                    } else if state.isLoading {
                        LoadingAlert(type: .short, message: nil)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? .black.opacity(0.15) : .clear)
                    
                )
                VStack {
                    HStack {
                        // 유료 아이콘
                        if !background.background.isFree {
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
                }
            }
            // 이름 라벨
            Text(background.background.backgroundName)
                .typography(isSelected ? .notosans14SB : .notosans14M)
                .foregroundStyle(isSelected ? .main500 : .black100)
        }
    }
}
