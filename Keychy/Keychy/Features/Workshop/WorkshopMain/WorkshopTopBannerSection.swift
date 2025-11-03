//
//  WorkshopTopBannerSection.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - Top Banner Section

extension WorkshopView {
    /// 상단 배너 (코인 버튼 + 타이틀)
    var topBannerSection: some View {
        VStack {
            HStack {
                Spacer()
                coinButton
            }

            Spacer()

            titleView
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }

    /// 스크롤 시 나타나는 상단 타이틀 바
    var topTitleBar: some View {
        HStack {
            titleView
            Spacer()
            coinButton
        }
        .padding(.top, 70)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(Color(UIColor.systemBackground))
        .opacity(viewModel.mainContentOffset - 80 < 70 ? 1 : 0)
    }

    /// 타이틀 뷰
    var titleView: some View {
        Text("작업실")
            .typography(.suit32B)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 코인 버튼
    var coinButton: some View {
        Button {
            router.push(.coinCharge)
        } label: {
            HStack(spacing: 0) {
                Image(.keyCoin)
                    .resizable()
                    .scaledToFit()

                Spacer()

                Text("\(userManager.currentUser?.coin ?? 0)")
                    .typography(.nanum16EB)
                    .foregroundColor(.black)
            }
        }
        .frame(minWidth: 80)
        .frame(height: 40)
        .fixedSize(horizontal: true, vertical: true)
        .buttonStyle(.glass)
    }
}
