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
    @Environment(UserManager.self) var userManager
    @State var viewModel: WorkshopViewModel
    @State private var hasInitialized = false

    let categories = ["KEYCHY!", "키링", "카라비너", "이펙트", "배경"]

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
            // 최초 한 번만 초기화
            if !hasInitialized {
                viewModel = WorkshopViewModel(userManager: userManager)
                hasInitialized = true

                // 1. 현재 선택된 카테고리만 먼저 로드 (빠른 초기 화면)
                await viewModel.fetchDataForCategory(viewModel.selectedCategory)
                await viewModel.loadOwnedItems()

                // 2. 백그라운드에서 나머지 카테고리 프리페칭
                Task.detached(priority: .background) {
                    await viewModel.prefetchRemainingData()
                }
            }
        }
        .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
            viewModel.resetFilters()

            // 카테고리 전환 시 해당 카테고리가 로드되지 않았다면 로드
            Task {
                await viewModel.fetchDataForCategory(newValue)
            }
        }
    }

    // MARK: Main Content

    /// 메인 스크롤 콘텐츠
    var mainScrollContent: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false){
                VStack(spacing: 0) {
                    // 상단 배너 (코인 버튼 + 타이틀)
                    topBannerSection
                        .frame(height: 150)
                        .id("top")

                    Spacer()
                        .frame(height: 20)

                    // 내 창고 섹션
                    myCollectionSection
                        .id("myCollection")

                    // 메인 콘텐츠 (그리드)
                    mainContentSection
                        .id("mainContent")
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
                .padding(.top, 60)
                .background(alignment: .top) {
                    Image("WorkshopBack")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .onAppear {
                // 저장된 카테고리와 스크롤 위치 복원
                if let savedCategory = viewModel.savedCategory {
                    // 카테고리 복원
                    viewModel.selectedCategory = savedCategory

                    // 스크롤 위치 복원 (아이템이 화면 중앙에 오도록)
                    if let savedPosition = viewModel.savedScrollPosition {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                scrollProxy.scrollTo(savedPosition, anchor: .center)
                            }
                        }
                    }

                    // 복원 후 초기화
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.savedScrollPosition = nil
                        viewModel.savedCategory = nil
                    }
                }
            }
        }
    }
}

// MARK: - Sort Sheet

extension WorkshopView {
    /// 정렬 선택 시트
    var sortSheet: some View {
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
        id: "2FcoxDhMhGR4dZtaQSdqZWqQzEp2",
        nickname: "런도",
        email: "bbpwj8qhnc@privaterelay.appleid.com"
    )
    userManager.currentUser?.templates = ["AcrylicPhoto"] // 보유 템플릿 ID 추가

    return WorkshopView(router: NavigationRouter<WorkshopRoute>())
        .environment(userManager)
}
