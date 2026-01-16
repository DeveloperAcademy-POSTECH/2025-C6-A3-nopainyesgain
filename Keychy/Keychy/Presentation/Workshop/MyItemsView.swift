//
//  MyItemsView.swift
//  Keychy
//
//  Created by rundo on 10/30/25.
//

import SwiftUI

struct MyItemsView: View {
    
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) private var userManager
    @State private var viewModel: WorkshopViewModel
    @State private var hasInitialized = false

    private let categories = ["템플릿", "카라비너", "이펙트", "배경"]
    
    /// 초기화 시점에는 Environment 접근 불가하므로 shared 인스턴스로 임시 생성
    /// 실제 userManager는 .task에서 교체됨
    init(router: NavigationRouter<WorkshopRoute>) {
        self.router = router
        _viewModel = State(initialValue: WorkshopViewModel(userManager: UserManager.shared))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 배경
            Color.white
                .ignoresSafeArea()

            // 메인 콘텐츠 (전체 화면)
            if viewModel.hasNetworkError {
                NoInternetView(topPadding: getSafeAreaTop() + 120, onRetry: {
                    Task {
                        await viewModel.retryFetchAllData()
                    }
                })
                .ignoresSafeArea()
            } else {
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
                .pullToRefresh(topPadding: 60) {
                    await viewModel.retryFetchAllData()
                }
                .adaptiveTopPaddingAlt()
                .padding(.top, 20)
            }

            // 헤더 오버레이 (항상 표시)
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    CategoryTabBar(
                        categories: categories,
                        selectedCategory: $viewModel.selectedCategory
                    )

                    filterBar
                        .padding(.bottom, 10)
                }
                .background(Color.white)

                Spacer()
            }
            .adaptiveTopPaddingAlt()
            .padding(.top, 20)

            customNavigationBar
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .swipeBackGesture(enabled: true)
        .task {
            // 네트워크 체크
            guard NetworkManager.shared.isConnected else {
                viewModel.hasNetworkError = true
                return
            }

            // 최초 한 번만 초기화
            if !hasInitialized {
                viewModel = WorkshopViewModel(userManager: userManager)
                hasInitialized = true

                await viewModel.fetchAllData()
            }
        }
        .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
            viewModel.resetFilters()
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            sortSheet
        }
    }
    
    /// 필터바
    private var filterBar: some View {
        WorkshopFilterBar(viewModel: $viewModel)
            .padding(.horizontal, 20)
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
            case "템플릿":
                WorkshopGridHelpers.itemGridView(
                    items: filteredOwnedTemplates,
                    isOwnedCheck: { _ in false },
                    router: router,
                    viewModel: viewModel,
                    emptyView: emptyContentView
                )
            case "배경":
                WorkshopGridHelpers.itemGridView(
                    items: filteredOwnedBackgrounds,
                    isOwnedCheck: { _ in false },
                    router: router,
                    viewModel: viewModel,
                    emptyView: emptyContentView
                )
            case "카라비너":
                WorkshopGridHelpers.itemGridView(
                    items: filteredOwnedCarabiners,
                    isOwnedCheck: { _ in false },
                    router: router,
                    viewModel: viewModel,
                    emptyView: emptyContentView
                )
            case "이펙트":
                WorkshopGridHelpers.effectGridView(
                    items: filteredOwnedEffects,
                    isSoundOwned: { _ in false },
                    isParticleOwned: { _ in false },
                    router: router,
                    viewModel: viewModel,
                    emptyView: emptyContentView
                )
            default:
                emptyContentView
            }
        }
    }
    
    /// 열쇠 충전 버튼
    private var chargeCoinBtn: some View {
        Button {
            router.push(.coinCharge)
        } label: {
            HStack(spacing: 0) {
                Image(.buyKey)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36)
                
                Text("\((userManager.currentUser?.coin ?? 0).formatted())")
                    .typography(.nanum16EB)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(height: 44)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
    
    /// 빈 콘텐츠 뷰
    private var emptyContentView: some View {
        VStack {
            
            Spacer()
                .frame(height: 280)
            
            Image(.emptyViewIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 124)
            
            Text("보유한 아이템이 없어요")
                .typography(.suit15R)
                .padding(.leading, 10)
        }
    }
    
    // MARK: - Filtering Logic
    
    /// 필터링된 보유 템플릿 목록
    private var filteredOwnedTemplates: [KeyringTemplate] {
        var result = viewModel.ownedTemplates
        
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
                return item1.useCount > item2.useCount
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
            sortedItems.sort { $0.useCount > $1.useCount }
        default:
            break
        }
        return sortedItems
    }
    
    /// 정렬 선택 시트
    private var sortSheet: some View {
        WorkshopSortSheet(
            showSheet: $viewModel.showFilterSheet,
            sortOrder: $viewModel.sortOrder
        )
    }
    
    /// 커스텀 네비
    private var customNavigationBar: some View {
        ZStack(alignment: .topTrailing) {
            // 네비바 (trailing 없이)
            CustomNavigationBar {
                BackToolbarButton {
                    TabBarManager.show()
                    router.pop()
                }
            } center: {
                Text("내 아이템")
                    .typography(.notosans17M)
            } trailing: {
                Spacer()
                    .frame(width: 44, height: 44)
            }

            // 코인 버튼 (오른쪽 상단에 별도 배치)
            chargeCoinBtn
                .padding(.trailing, 16)
                .padding(.top, getSafeAreaTop())
        }
    }

}

/// Safe Area Top 계산
private func getSafeAreaTop() -> CGFloat {
    guard let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first?.windows
        .first(where: { $0.isKeyWindow }) else {
        return 0
    }
    return window.safeAreaInsets.top
}

