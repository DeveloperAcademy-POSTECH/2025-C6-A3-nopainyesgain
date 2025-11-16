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
                myItemBtn
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
            myItemBtn
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(Color.white100)
        .opacity(viewModel.mainContentOffset - 80 < 70 ? 1 : 0)
    }

    /// 타이틀 뷰
    var titleView: some View {
        Text("공방")
            .typography(.nanum32EB)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 내 아이템 버튼
    var myItemBtn: some View {
        Button {
            router.push(.myItems)
        } label: {
            HStack(spacing: 0) {
                Image(.myItem)
                    .resizable()
                    .scaledToFit()

                Spacer()

                Text("내 아이템")
                    .typography(.suit17B)
                    .foregroundColor(.black)
            }
        }
        .frame(minWidth: 80)
        .frame(height: 44)
        .fixedSize(horizontal: true, vertical: true)
        .buttonStyle(.glass)
    }
}
