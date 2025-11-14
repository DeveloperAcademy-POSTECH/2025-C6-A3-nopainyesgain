//
//  WorkshopMyCollectionSection.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - My Collection Section

extension WorkshopView {
    /// 내 창고 섹션 (보유한 키링만 표시)
    var myCollectionSection: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
                Button("내 창고 >") {
                    router.push(.myItems)
                }
                .typography(.suit16B)
                .foregroundColor(.black.opacity(0.7))

                Spacer()
            }

            // 보유 아이템 리스트
            Group {
                if viewModel.isLoading || !viewModel.hasLoadedOwnedItems {
                    loadingOwnedView
                } else {
                    if viewModel.ownedTemplates.isEmpty {
                        emptyOwnedView
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(viewModel.ownedTemplates) { template in
                                    OwnedItemCard(item: template, router: router, viewModel: viewModel)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    /// 빈 창고 뷰
    var emptyOwnedView: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("최근 사용한 템플릿이 없어요")
                .typography(.suit13SB)
                .foregroundColor(.gray500)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 135)
        .padding(.bottom, 1)
        .background(.white70)
        .cornerRadius(10)
    }

    /// 내 창고 로딩 중 뷰
    var loadingOwnedView: some View {
        HStack(alignment: .center, spacing: 0) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 135)
    }
}
