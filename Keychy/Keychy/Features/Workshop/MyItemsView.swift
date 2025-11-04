//
//  MyItemsView.swift
//  Keychy
//
//  Created by rundo on 10/30/25.
//

import SwiftUI

struct MyItemsView: View {

    @Environment(UserManager.self) private var userManager
    @State private var viewModel: WorkshopViewModel

    private let categories = ["키링", "카라비너", "이펙트", "배경"]

    /// 초기화 시점에는 Environment 접근 불가하므로 shared 인스턴스로 임시 생성
    /// 실제 userManager는 .task에서 교체됨
    init() {
        _viewModel = State(initialValue: WorkshopViewModel(userManager: UserManager.shared))
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 스크롤 콘텐츠 (그리드만)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 메인 콘텐츠 (그리드)
                    mainContentSection
                        .padding(.top, 20)
                }
            }

            // 상단 고정 영역 (카테고리 바 + 필터바)
            VStack(spacing: 0) {
                CategoryTabBar(
                    categories: categories,
                    selectedCategory: $viewModel.selectedCategory
                )
                .padding(.top, 16)
                .padding(.horizontal, 20)

                // 필터바
                filterBar
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationTitle("내 창고")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel = WorkshopViewModel(userManager: userManager)
            await viewModel.fetchAllData()
            await viewModel.loadOwnedItems()
        }
        .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
            viewModel.resetFilters()
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            sortSheet
        }
    }

    /// 카테고리에 따라 다른 필터바 표시
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 정렬 버튼
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

                // 카테고리별 필터
                categorySpecificFilters
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    /// 카테고리별 필터 옵션
    private var categorySpecificFilters: some View {
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

    // MARK: - Main Content Section

    /// 메인 콘텐츠 영역 (카테고리별 그리드)
    private var mainContentSection: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else {
                categoryContent
            }
        }
    }

    /// 로딩 뷰
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }

    /// 카테고리별 콘텐츠
    private var categoryContent: some View {
        Group {
            switch viewModel.selectedCategory {
            case "키링":
                WorkshopGridHelpers.itemGridView(
                    items: filteredOwnedTemplates,
                    isOwnedCheck: { _ in false },
                    router: nil,
                    viewModel: nil,
                    emptyView: emptyContentView
                )
            case "배경":
                WorkshopGridHelpers.itemGridView(
                    items: filteredOwnedBackgrounds,
                    isOwnedCheck: { _ in false },
                    router: nil,
                    viewModel: nil,
                    emptyView: emptyContentView
                )
            case "카라비너":
                WorkshopGridHelpers.itemGridView(
                    items: filteredOwnedCarabiners,
                    isOwnedCheck: { _ in false },
                    router: nil,
                    viewModel: nil,
                    emptyView: emptyContentView
                )
            case "이펙트":
                WorkshopGridHelpers.effectGridView(
                    items: filteredOwnedEffects,
                    isSoundOwned: { _ in false },
                    isParticleOwned: { _ in false },
                    router: nil,
                    viewModel: nil,
                    emptyView: emptyContentView
                )
            default:
                emptyContentView
            }
        }
    }

    /// 빈 콘텐츠 뷰
    private var emptyContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.purple).opacity(0.6)

            Text("보유한 아이템이 없어요")
                .typography(.suit14SB18)
                .foregroundColor(.gray500)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }

    // MARK: - Filtering Logic

    /// 필터링된 보유 템플릿 목록
    private var filteredOwnedTemplates: [KeyringTemplate] {
        var result = viewModel.ownedTemplates

        if let filter = viewModel.selectedTemplateFilter {
            switch filter {
            case .image:
                result = result.filter { $0.tags.contains("이미지형") }
            case .text:
                result = result.filter { $0.tags.contains("텍스트형") }
            case .drawing:
                result = result.filter { $0.tags.contains("드로잉형") }
            }
        }

        return applySorting(to: result)
    }

    private var filteredOwnedBackgrounds: [Background] {
        var result = viewModel.ownedBackgrounds

        if let filter = viewModel.selectedCommonFilter {
            result = result.filter { $0.tags.contains(filter) }
        }

        return applySorting(to: result)
    }

    private var filteredOwnedCarabiners: [Carabiner] {
        var result = viewModel.ownedCarabiners

        if let filter = viewModel.selectedCommonFilter {
            result = result.filter { $0.tags.contains(filter) }
        }

        return applySorting(to: result)
    }

    /// 필터링된 보유 이펙트 목록
    private var filteredOwnedEffects: [any WorkshopItem] {
        var result: [any WorkshopItem] = []

        switch viewModel.selectedEffectFilter {
        case .sound:
            result = viewModel.ownedSounds
        case .particle:
            result = viewModel.ownedParticles
        case nil:
            // 필터가 없으면 사운드와 파티클 모두 표시
            result = (viewModel.ownedSounds as [any WorkshopItem]) + (viewModel.ownedParticles as [any WorkshopItem])
        }

        // any WorkshopItem 배열에 대한 정렬
        return result.sorted { item1, item2 in
            switch viewModel.sortOrder {
            case "최신순":
                return item1.createdAt > item2.createdAt
            case "인기순":
                return item1.downloadCount > item2.downloadCount
            default:
                return false
            }
        }
    }

    /// 정렬 적용
    private func applySorting<T: WorkshopItem>(to items: [T]) -> [T] {
        var sortedItems = items
        switch viewModel.sortOrder {
        case "최신순":
            sortedItems.sort { $0.createdAt > $1.createdAt }
        case "인기순":
            sortedItems.sort { $0.downloadCount > $1.downloadCount }
        default:
            break
        }
        return sortedItems
    }

    // MARK: - Sort Sheet

    /// 정렬 선택 시트
    private var sortSheet: some View {
        WorkshopSortSheet(
            showSheet: $viewModel.showFilterSheet,
            sortOrder: $viewModel.sortOrder
        )
    }
}

#Preview {
    NavigationStack {
        MyItemsView()
            .environment(UserManager.shared)
    }
}
