//
//  festivalCard.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import SwiftUI
import NukeUI

struct festivalCard: View {
    let title: String
    let location: String
    let dateRange: String
    let distance: String
    let imageName: String
    let isLocked: Bool
    let enterAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 이미지
            Image(imageName)
                .resizable()
                .scaledToFit()
            
            Spacer().frame(height: 15)
            
            // 페스티벌 정보
            HStack {
                Text(title)
                    .typography(.suit24B)
                    .foregroundStyle(.black100)
                Spacer()
            }
            .padding(.horizontal, 8)
            HStack {
                Text(location)
                    .typography(.suit14M)
                Spacer()
            }
            .padding(.horizontal, 8)
            
            
            Spacer().frame(height: 28)
            
            Text("내 위치로부터 1.5km")
                .typography(.suit14SB)
                .foregroundStyle(.main500)
                .opacity(isLocked ? 1 : 0)
            
            Spacer().frame(height: 3)
            
            Button {
                enterAction()
            } label: {
                Text("입장하기")
                    .typography(isLocked ? .suit17M : .suit17B)
                    .foregroundStyle(isLocked ? .gray300 : .white100)
                    .padding(.vertical, 13.5)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 34)
                            .fill(isLocked ? .gray50 : .main500)
                    )
            }
            .disabled(isLocked)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 29)
                .fill(.white100)
                .frame(width: screenWidth * 0.75)
                .shadow(color: .black15, radius: 4)
        )
    }
}
