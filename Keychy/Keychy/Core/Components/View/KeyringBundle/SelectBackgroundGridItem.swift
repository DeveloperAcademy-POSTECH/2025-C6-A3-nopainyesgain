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
            ZStack(alignment: .top) {
                // 배경 이미지
                LazyImage(url: URL(string: background.background.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else if state.isLoading {
                        LoadingAlert(type: .short, message: nil)
                    }
                }
                .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? .black.opacity(0.15) : .clear)
                    
                )
                VStack {
                    HStack {
                        // 유료 아이콘
                        Image(.paidIcon)
                            .padding(.top, 3)
                            .opacity(background.background.isFree ? 0 : 1)
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
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .opacity(background.isOwned ? 1 : 0)
                    }
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.trailing, 7)
            }
            // 이름 라벨
            Text(background.background.backgroundName)
                .typography(isSelected ? .notosans14SB : .notosans14M)
                .foregroundStyle(isSelected ? .main500 : .black100)
        }
    }
}
