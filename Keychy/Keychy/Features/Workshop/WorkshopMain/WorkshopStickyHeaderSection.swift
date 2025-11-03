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

    /// 카테고리에 따라 다른 필터바 표시
    var filterBar: some View {
        HStack(spacing: 8) {
            // 정렬 버튼 (고정)
            Button {
                viewModel.showFilterSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.sortOrder)
                        .typography(.suit14SB18)
                        .foregroundColor(.gray500)

                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray500)

                }
                .padding(.horizontal, Spacing.gap)
                .padding(.vertical, Spacing.sm)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.gray50)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // 카테고리별 필터 (스크롤 가능)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categorySpecificFilters
                }
            }
        }
        .padding(.top, 12)
    }


    /// 카테고리별 필터 옵션
    var categorySpecificFilters: some View {
        Group {
            switch viewModel.selectedCategory {
            case "키링":
                // 템플릿 필터 (이미지형, 텍스트형, 드로잉형)
                ForEach(TemplateFilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedTemplateFilter == filter
                    ) {
                        viewModel.selectedTemplateFilter =
                            viewModel.selectedTemplateFilter == filter ? nil : filter
                    }
                }

            case "이펙트":
                // 이펙트 타입 필터 (사운드, 파티클)
                ForEach(EffectFilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedEffectFilter == filter
                    ) {
                        viewModel.selectedEffectFilter =
                            viewModel.selectedEffectFilter == filter ? nil : filter
                    }
                }

            case "카라비너":
                // 카라비너 태그 (동적으로 로드)
                ForEach(viewModel.availableCarabinerTags, id: \.self) { tag in
                    FilterChip(
                        title: tag,
                        isSelected: viewModel.selectedCommonFilter == tag
                    ) {
                        viewModel.selectedCommonFilter =
                            viewModel.selectedCommonFilter == tag ? nil : tag
                    }
                }

            case "배경":
                // 배경 태그 (동적으로 로드)
                ForEach(viewModel.availableBackgroundTags, id: \.self) { tag in
                    FilterChip(
                        title: tag,
                        isSelected: viewModel.selectedCommonFilter == tag
                    ) {
                        viewModel.selectedCommonFilter =
                            viewModel.selectedCommonFilter == tag ? nil : tag
                    }
                }

            default:
                EmptyView()
            }
        }
    }
}
