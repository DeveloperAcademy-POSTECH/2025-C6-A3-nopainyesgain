//
//  WorkshopTemplatesView.swift
//  Keychy
//
//  Created by rundo on 11/24/25.
//

import SwiftUI

struct WorkshopTemplatesView: View {

    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) private var userManager
    @State private var viewModel: WorkshopViewModel
    @State private var hasInitialized = false

    init(router: NavigationRouter<WorkshopRoute>) {
        self.router = router
        _viewModel = State(initialValue: WorkshopViewModel(userManager: UserManager.shared))
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 스크롤 콘텐츠 (그리드만)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 메인 콘텐츠 (그리드)
                    mainContentSection
                        .background(
                            GeometryReader { geo in
                                let minY = geo.frame(in: .global).minY
                                Color.clear
                                    .onAppear {
                                        viewModel.mainContentOffset = minY
                                    }
                                    .onChange(of: minY) { oldValue, newValue in
                                        viewModel.mainContentOffset = newValue
                                    }
                            }
                        )
                }
            }
            .adaptiveTopPaddingAlt()

            // 상단 고정 영역 (필터바 + 칩바)
            VStack(spacing: 0) {
                filterBar
            }
            .background(Color.white100)
            .adaptiveTopPaddingAlt()

            customNavigationBar
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task {
            if !hasInitialized {
                viewModel = WorkshopViewModel(userManager: userManager)
                hasInitialized = true

                await viewModel.fetchDataForCategory("템플릿")
            }
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            sortSheet
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
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

            // 템플릿 필터 칩
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TemplateFilterType.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: viewModel.selectedTemplateFilter == filter
                        ) {
                            viewModel.selectedTemplateFilter =
                                viewModel.selectedTemplateFilter == filter ? nil : filter
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 20)
    }

    // MARK: - Main Content Section

    private var mainContentSection: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else {
                templateGridContent
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }

    private var templateGridContent: some View {
        Group {
            if filteredTemplates.isEmpty {
                emptyContentView
            } else {
                WorkshopGridHelpers.itemGridView(
                    items: filteredTemplates,
                    isOwnedCheck: { _ in false },
                    router: router,
                    viewModel: viewModel,
                    emptyView: emptyContentView
                )
            }
        }
    }

    private var emptyContentView: some View {
        VStack {
            Spacer()
                .frame(height: 280)

            Image(.emptyViewIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 124)

            Text("템플릿이 없어요")
                .typography(.suit15R)
                .padding(.leading, 10)
        }
    }

    // MARK: - Filtering Logic

    private var filteredTemplates: [KeyringTemplate] {
        var result = viewModel.templates

        if let filter = viewModel.selectedTemplateFilter {
            switch filter {
            case .image:
                result = result.filter { $0.tags.contains("이미지") }
            case .text:
                result = result.filter { $0.tags.contains("텍스트") }
            case .drawing:
                result = result.filter { $0.tags.contains("드로잉") }
            }
        }

        return applySorting(to: result)
    }

    private func applySorting<T: WorkshopItem>(to items: [T]) -> [T] {
        var sortedItems = items
        switch viewModel.sortOrder {
        case "최신순":
            sortedItems.sort { $0.createdAt > $1.createdAt }
        case "인기순":
            sortedItems.sort { $0.useCount > $1.useCount }
        default:
            break
        }
        return sortedItems
    }

    // MARK: - Sort Sheet

    private var sortSheet: some View {
        WorkshopSortSheet(
            showSheet: $viewModel.showFilterSheet,
            sortOrder: $viewModel.sortOrder
        )
    }

    // MARK: - Custom Navigation Bar

    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            Text("템플릿")
                .typography(.notosans17M)
        } trailing: {
            Spacer()
                .frame(width: 44, height: 44)
        }
    }
}
