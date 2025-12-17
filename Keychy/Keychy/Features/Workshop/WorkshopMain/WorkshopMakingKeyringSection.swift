//
//  WorkshopMakingKeyringSection.swift
//  Keychy
//
//  Created by rundo on 11/24/25.
//

import SwiftUI
import NukeUI

// MARK: - MakingKeyring Section

extension WorkshopView {
    var makingKeyringSection: some View {
        VStack(spacing: 0) {
            // 제목
            Text("내 마음대로 고르는\n다양한 템플릿(๑' ᵕ '๑)⸝*")
                .typography(.suit16B)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .padding(.top, 13)
                .padding(.bottom, 10)
            
            workshopBannerImage
            
            // 키링 만들기 버튼
            Button {
                router.push(.workshopTemplates)
            } label: {
                ZStack {
                    // 바탕 레이어
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.main400)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    
                    // 버튼 제목
                    Text("+ 키링 만들기")
                        .typography(.suit17B)
                        .foregroundStyle(Color.white100)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .background(Color.white50)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white70, lineWidth: 1)
        )
        .padding(.horizontal, 15)
        .padding(.bottom, 12)
    }
    
    // MARK: - Workshop Banner Image
    private var workshopBannerImage: some View {
        HStack(spacing: 0) {
            ZStack {
                // 썸네일 (로딩 중)
                if viewModel.isWorkshopBannerLoading {
                    Image(.workshopBannerThumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                }
                
                // GIF
                NukeAnimatedImageView(
                    url: URL(string: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Workshop%2FworkshopBanner200.gif?alt=media&token=9ce6c06a-88d3-4fd5-b6df-6a96224c8c35"),
                    isLoading: $viewModel.isWorkshopBannerLoading,
                    maxSize: CGSize(width: 1800, height: 1800)
                )
                .scaledToFit()
                .frame(height: 120)
            }
        }
        .padding(.bottom, 10)
    }
}


