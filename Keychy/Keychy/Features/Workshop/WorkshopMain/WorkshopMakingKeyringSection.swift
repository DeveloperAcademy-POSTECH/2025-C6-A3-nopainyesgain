//
//  WorkshopMakingKeyringSection.swift
//  Keychy
//
//  Created by rundo on 11/24/25.
//

import SwiftUI

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

            // 키링 이미지들 (가로 배치) - GIF 애니메이션
            HStack(spacing: 0) {
                SimpleAnimatedImage(
                    url: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Workshop%2FmakingKeyringTemp.gif?alt=media&token=144b0aff-5335-4e8c-b447-f9357118e513",
                    maxSize: CGSize(width: 600, height: 600)
                )
                .frame(height: 120)
                .scaledToFit()
            }
            .padding(.bottom, 10)
            
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
}
