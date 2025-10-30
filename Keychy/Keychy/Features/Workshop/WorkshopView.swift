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
    
    private let categories = ["KEYCHY!", "키링", "카라비너", "파티클", "사운드", "배경"]
        
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
        ScrollView {
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
        .animation(.easeInOut(duration: 0.25), value: viewModel.mainContentOffset)
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
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.pink)
                
                Spacer()

                Text("\(userManager.currentUser?.coin ?? 0)")
                    .typography(.suit15R)
                    .foregroundColor(.black)
            }
            .padding(.vertical, 3)
        }
        .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
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
        .background(Color(UIColor.systemBackground))
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
                            .foregroundColor(.white100)
                        
                        Image("ChevronDown")
                            .resizable()
                    }
                    .padding(.horizontal, Spacing.gap)
                    .padding(.vertical, Spacing.sm)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.black70)
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
                
            case "카라비너", "파티클", "사운드", "배경":
                // 공통 필터 (귀여움, 심플, 자연)
                ForEach(CommonFilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedCommonFilter == filter
                    ) {
                        viewModel.selectedCommonFilter =
                            viewModel.selectedCommonFilter == filter ? nil : filter
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
                .foregroundColor(Color(.secondaryGray))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    /// 빈 창고 뷰
    private var emptyOwnedView: some View {
        VStack(spacing: 8) {
            Text("보유한 아이템이 없습니다.")
                .typography(.suit14SB18)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 137)
    }
    
    /// 내 창고 로딩 중 뷰
    private var loadingOwnedView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
            Text("불러오는 중...")
                .typography(.suit14SB18)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

        }
        .frame(height: 137)
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
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.5)

            Text("불러오는 중...")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
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
            case "파티클":
                itemGridView(items: viewModel.filteredParticles,
                           isOwnedCheck: viewModel.isParticleOwned)
            case "사운드":
                itemGridView(items: viewModel.filteredSounds,
                           isOwnedCheck: viewModel.isSoundOwned)
            default:
                emptyContentView
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
                ], spacing: 16) {
                    ForEach(items) { item in
                        WorkshopItemView(
                            item: item,
                            isOwned: isOwnedCheck(item),
                            router: router
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
            }
        }
    }
    
    /// KEYCHY! 전용 콘텐츠 (준비 중)
    private var keychyContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.purple).opacity(0.6)

            Text("KEYCHY! \n콘텐츠 준비중")
                .typography(.suit14SB18)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    /// 빈 콘텐츠 뷰
    private var emptyContentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("표시할 아이템이 없습니다")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 100)
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
        VStack(spacing: 0) {
            // 헤더
            sheetHeader
            
            Divider()
            
            // 정렬 옵션
            sortOptions
            
            Spacer()
        }
        .presentationDetents([.height(200)])
    }
    
    /// 시트 헤더
    private var sheetHeader: some View {
        HStack {
            Button {
                viewModel.showFilterSheet = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Text("정렬 기준")
                .font(.headline)
            
            Spacer()
            
            Color.clear
                .frame(width: 24)
        }
        .padding()
    }
    
    /// 정렬 옵션 리스트
    private var sortOptions: some View {
        VStack(spacing: 0) {
            ForEach(["최신순", "인기순"], id: \.self) { sort in
                SortOption(
                    title: sort,
                    isSelected: viewModel.sortOrder == sort
                ) {
                    viewModel.sortOrder = sort
                    viewModel.applySorting()
                    viewModel.showFilterSheet = false
                }
            }
        }
    }
}

// MARK: - Reusable Components


/// 필터 칩 버튼
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .typography(.suit14SB18)
                    .foregroundColor(isSelected ? Color(.systemBackground) : .gray500)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.black70 : Color.gray50)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 정렬 옵션 행
struct SortOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.pink)
                }
            }
            .padding()
        }
    }
}

// MARK: - Workshop Item Views

/// 모든 워크샵 아이템을 표시하는 통합 그리드 아이템 뷰
struct WorkshopItemView<Item: WorkshopItem>: View {
    let item: Item
    var isOwned: Bool = false
    var router: NavigationRouter<WorkshopRoute>? = nil
    
    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 8) {
                // 썸네일 이미지
                thumbnailImage
                
                // 아이템 이름
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// 썸네일 이미지 + 가격 오버레이
    private var thumbnailImage: some View {
        ZStack(alignment: .topLeading) {
            LazyImage(url: URL(string: item.thumbnailURL)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if state.isLoading {
                    Color.gray.opacity(0.3)
                        .overlay { ProgressView() }
                } else {
                    Color.gray.opacity(0.3)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 가격 오버레이
            priceOverlay(
                isFree: item.isFree,
                price: item.workshopPrice,
                isOwned: isOwned
            )
        }
    }
    
    /// 탭 핸들러 (KeyringTemplate만 네비게이션)
    private func handleTap() {
        if let template = item as? KeyringTemplate,
           let router = router,
           let route = WorkshopRoute.from(string: template.id!) {
            router.push(route)
        }
    }
}

/// 보유한 아이템을 표시하는 작은 카드 뷰
struct OwnedItemCard<Item: WorkshopItem>: View {
    let item: Item
    var router: NavigationRouter<WorkshopRoute>? = nil
    
    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 8) {
                LazyImage(url: URL(string: item.thumbnailURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.isLoading {
                        ProgressView()
                    } else {
                        Color.gray.opacity(0.1)
                    }
                }
                .padding(8)
                .frame(width:112, height:112)
                .background(Color.white)
                .cornerRadius(10)
                
                // 아이템 이름
                Text(item.name)
                    .typography(.suit14SB18)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// 탭 핸들러 (KeyringTemplate만 네비게이션)
    private func handleTap() {
        if let template = item as? KeyringTemplate,
           let router = router,
           let route = WorkshopRoute.from(string: template.id!) {
            router.push(route)
        }
    }
}

/// 공통 가격 오버레이 (보유/무료/유료 표시)
func priceOverlay(isFree: Bool, price: Int, isOwned: Bool) -> some View {
    VStack {
        HStack {
            if isOwned {
                // 보유 배지
                Text("보유")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
                    .padding(8)
            } else if !isFree {
                // 가격 배지
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.pink)
                    Text("\(price)")
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)
            }
            Spacer()
        }
        Spacer()
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
