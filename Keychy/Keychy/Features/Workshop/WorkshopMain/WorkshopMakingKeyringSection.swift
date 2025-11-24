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
            Text("나만의 키링을 만드는 템플릿 공방")
                .typography(.suit16B)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 13)
                .padding(.bottom, 14)
            
            // 키링 이미지들 (가로 배치)
            HStack(spacing: 0) {
                Image(.makingKeyring)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
            }
            .padding(.bottom, 10)
            
            // 키링 만들기 버튼
            Button {
                router.push(.workshopTemplates)
            } label: {
                ZStack {
                    // 바탕 레이어
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.main100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white30, lineWidth: 2)
                        )
                    
                    // 안쪽 블러 레이어
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.main400)
                        .padding(.horizontal, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .blur(radius: 9.65)
                        .mask(
                            RoundedRectangle(cornerRadius: 15)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        )

                    // 버튼 제목
                    Text("+ 키링 만들기")
                        .typography(.suit17B)
                        .foregroundStyle(Color.white100)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(Color.white30)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white70, lineWidth: 1)
        )
        .padding(.horizontal, 15)
        .padding(.bottom, 20)
    }
}
