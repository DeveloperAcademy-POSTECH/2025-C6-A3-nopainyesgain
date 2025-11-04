//
//  WorkshopStickyHeaderSection.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - Sticky Header Section

extension WorkshopView {
    /// 스티키 헤더 (카테고리 + 필터)
    var stickyHeaderSection: some View {
        VStack(spacing: 0) {
            // 카테고리 탭바
            CategoryTabBar(
                categories: categories,
                selectedCategory: $viewModel.selectedCategory
            )
            .padding(.top, 16)

            // 필터바
            filterBar
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(.white)
        .clipShape(.rect(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
        .offset(y: max(120, min(730, viewModel.mainContentOffset - 20)))
    }

    /// 필터바
    var filterBar: some View {
        WorkshopFilterBar(viewModel: $viewModel)
    }
}
