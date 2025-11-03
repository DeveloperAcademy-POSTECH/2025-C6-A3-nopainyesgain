//
//  SelectBackgroundGridItem.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI

struct SelectBackgroundGridItem: View {
    let background: BackgroundViewData
    @State private var backgroundImage: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if let image = backgroundImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if hasError {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                }
            }
            .overlay(
                VStack {
                    HStack {
                        // 유료 배경은 유료 아이콘 표시
                        if !background.background.isFree {
                            Image(.cherries)
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
                        }
                    }
                    Spacer()
                }
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
            )
            .task {
                do {
                    backgroundImage = try await
                    StorageManager.shared.getImage(path: background.background.backgroundImage)
                    isLoading = false
                } catch {
                    hasError = true
                    isLoading = false
                    print("배경 이미지 로드 실패: \(error)")
                }
            }
            Text(background.background.backgroundName)
                .typography(.suit14SB18)
                .foregroundStyle(Color.black100)
        } //:VSTACK
    }
}
