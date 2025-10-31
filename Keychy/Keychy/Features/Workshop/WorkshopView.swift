//
//  WorkshopView.swift
//  Keychy
//
//  Created by rundo on 10/16/25.
//

import SwiftUI
import NukeUI

// MARK: - Main View

struct WorkshopView: View {
    
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) private var userManager
    @State private var viewModel: WorkshopViewModel
    
    private let categories = ["KEYCHY!", "키링", "카라비너", "이펙트", "배경"]
        
    /// 초기화 시점에는 Environment 접근 불가하므로 shared 인스턴스로 임시 생성
    /// 실제 userManager는 .task에서 교체됨
    init(router: NavigationRouter<WorkshopRoute>) {
        self.router = router
        _viewModel = State(initialValue: WorkshopViewModel(userManager: UserManager.shared))
    }
        
    var body: some View {
        ZStack(alignment: .top) {
            // 메인 스크롤 콘텐츠
            mainScrollContent
            
            // 스크롤 시 나타나는 상단 타이틀 바
            topTitleBar
            
            // 스티키 헤더 (카테고리 탭 + 필터)
            stickyHeaderSection
        }
        .background(
            Image(.back)
                .resizable()
                .scaledToFill()
        )
        .ignoresSafeArea()
        .sheet(isPresented: $viewModel.showFilterSheet) {
            sortSheet
        }
        .task {
            viewModel = WorkshopViewModel(userManager: userManager)
            await viewModel.fetchAllData()
            await viewModel.loadOwnedItems()
        }
        .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
            viewModel.resetFilters()
        }
    }
    
    // MARK: Main Content
    
    /// 메인 스크롤 콘텐츠
    private var mainScrollContent: some View {
        ScrollView(showsIndicators: false){
            VStack(spacing: 0) {
                // 상단 배너 (코인 버튼 + 타이틀)
                topBannerSection
                    .frame(height: 150)
                
                Spacer()
                    .frame(height: 20)
                
                // 내 창고 섹션
                myCollectionSection
                
                // 메인 콘텐츠 (그리드)
                VStack {
                    mainContentSection
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
                                        viewModel.mainContentOffset = newValue
                                    }
                            }
                        )
                }
                .background(Color(UIColor.systemBackground))
            }
            .padding(.top, 60)
            .background(alignment: .top) {
                Image("WorkshopBack")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

// MARK: - Top Banner Section

extension WorkshopView {
    /// 상단 배너 영역 (초기 화면)
    private var topBannerSection: some View {
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
    private var topTitleBar: some View {
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
//        .animation(.easeInOut(duration: 0.2), value: viewModel.mainContentOffset)
    }
    
    /// 타이틀 텍스트
    private var titleView: some View {
        Text("공방")
            .typography(.suit32B)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 코인 버튼
    private var coinButton: some View {
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

// MARK: - Sticky Header Section

extension WorkshopView {
    /// 스티키 헤더 (카테고리 + 필터)
    private var stickyHeaderSection: some View {
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
}

// MARK: - My Collection Section

extension WorkshopView {
    /// 내 창고 섹션 (보유한 템플릿)
    private var myCollectionSection: some View {
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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    if viewModel.isLoading {
                        loadingOwnedView
                    } else if viewModel.ownedTemplates.isEmpty {
                        emptyOwnedView
                    } else {
                        ForEach(viewModel.ownedTemplates) { template in
                            OwnedItemCard(item: template, router: router)
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 20)
    }
    
    /// 빈 창고 뷰
    private var emptyOwnedView: some View {
        HStack(spacing: 0) {
            Spacer()
            Text("내 창고가 비었어요")
                .typography(.suit14SB18)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(width: 343, height: 112)
        .background(Color.white.opacity(0.4))
        .cornerRadius(10)
    }
    
    /// 내 창고 로딩 중 뷰
    private var loadingOwnedView: some View {
        HStack(spacing: 0) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
            Spacer()
        }
        .frame(width: 343, height: 113)
    }

}

// MARK: - Main Content Section

extension WorkshopView {
    /// 메인 콘텐츠 영역 (카테고리별 그리드)
    private var mainContentSection: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else {
                categoryContent
            }
        }
    }
    
    /// 로딩 뷰
    private var loadingView: some View {
        HStack(spacing: 0) {
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
            case "KEYCHY!":
                keychyContentView
            case "키링":
                itemGridView(items: viewModel.filteredTemplates,
                           isOwnedCheck: viewModel.isTemplateOwned)
            case "배경":
                itemGridView(items: viewModel.filteredBackgrounds,
                           isOwnedCheck: viewModel.isBackgroundOwned)
            case "카라비너":
                itemGridView(items: viewModel.filteredCarabiners,
                           isOwnedCheck: viewModel.isCarabinerOwned)
            case "이펙트":
                effectContentView
            default:
                emptyContentView
            }
        }
    }
    
    /// 이펙트 전용 콘텐츠 (사운드 + 파티클)
    private var effectContentView: some View {
        Group {
            let items = viewModel.filteredEffects
            
            if items.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        if let sound = item as? Sound {
                            WorkshopItemView(
                                item: sound,
                                isOwned: viewModel.isSoundOwned(sound),
                                router: router
                            )
                        } else if let particle = item as? Particle {
                            WorkshopItemView(
                                item: particle,
                                isOwned: viewModel.isParticleOwned(particle),
                                router: router
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
            }
        }
    }
    
    /// 통합 아이템 그리드 뷰
    private func itemGridView<T: WorkshopItem>(
        items: [T],
        isOwnedCheck: @escaping (T) -> Bool
    ) -> some View {
        Group {
            if items.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 11) {
                    ForEach(items) { item in
                        WorkshopItemView(
                            item: item,
                            isOwned: isOwnedCheck(item),
                            router: router
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 92)
            }
        }
    }
    
    /// KEYCHY! 전용 콘텐츠 (준비 중)
    private var keychyContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.purple).opacity(0.6)

            Text("KEYCHY! 디자이너 열일중..")
                .typography(.suit14SB18)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }
    
    /// 빈 콘텐츠 뷰
    private var emptyContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.purple).opacity(0.6)
            
            Text("Comming Soon~")
                .typography(.suit14SB18)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }
    
    /// 에러 뷰
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("다시 시도") {
                Task {
                    await viewModel.fetchAllData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 100)
    }
}

// MARK: - Sort Sheet

extension WorkshopView {
    /// 정렬 선택 시트
    private var sortSheet: some View {
        WorkshopSortSheet(
            showSheet: $viewModel.showFilterSheet,
            sortOrder: $viewModel.sortOrder
        )
        .onChange(of: viewModel.sortOrder) { oldValue, newValue in
            viewModel.applySorting()
        }
    }
}

// MARK: - Preview

#Preview {
    let userManager = UserManager.shared
    
    // 프리뷰용 더미 유저 생성
    userManager.currentUser = KeychyUser(
        id: "preview-user-id",
        nickname: "프리뷰유저",
        email: "preview@example.com"
    )
    userManager.currentUser?.templates = ["AcrylicPhoto", "CirclePhoto", "CloudDream", "MinimalSquare"] // 보유 템플릿 ID 추가
        
    return WorkshopView(router: NavigationRouter<WorkshopRoute>())
        .environment(userManager)
}
