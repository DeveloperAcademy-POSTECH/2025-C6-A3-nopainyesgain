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
    @State private var isTabBarVisible = true
    
    let categories = ["템플릿", "카라비너", "이펙트", "배경"]
    
    /// WorkshopTab에서 생성된 viewModel을 받아서 사용
    init(router: NavigationRouter<WorkshopRoute>, viewModel: WorkshopViewModel) {
        self.router = router
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.hasNetworkError {
                networkErrorView
            } else {
                ZStack(alignment: .top) {
                    // 메인 스크롤 콘텐츠
                    mainScrollContent

                    // 스크롤 시 나타나는 상단 타이틀 바
                    topTitleBar

                    // 스티키 헤더 (카테고리 탭 + 필터)
                    stickyHeaderSection

                    // 상단 그라데이션 블러 오버레이
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .ignoresSafeArea(edges: .top)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
                .background(
                    Image(.back)
                        .resizable()
                        .scaledToFill()
                )
            }
        }
        .ignoresSafeArea()
        .toolbar(isTabBarVisible ? .visible : .hidden, for: .tabBar)
        .sheet(isPresented: $viewModel.showFilterSheet) {
            sortSheet
        }
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

                // 1. 현재 선택된 카테고리만 먼저 로드 (빠른 초기 화면)
                await viewModel.fetchDataForCategory(viewModel.selectedCategory)
                // Workshop 배너는 Home에서 이미 prefetch됨

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
        .withToast(position: .tabbar)
    }

    // MARK: Main Content
    
    /// 메인 스크롤 콘텐츠
    var mainScrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 상단 배너 (코인 버튼 + 타이틀)
                topBannerSection
                
                Spacer()
                    .frame(height: 64)
                
                makingKeyringSection
                
                Spacer()
                    .frame(height: 14)

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
            .padding(.top, 60)
            .background(alignment: .top) {
                Image(.workshopBG)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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

// MARK: - Network Error

extension WorkshopView {
    /// 네트워크 에러 화면
    private var networkErrorView: some View {
        ZStack(alignment: .top) {
            NoInternetView(topPadding: getSafeAreaTop() + 40, onRetry: {
                Task {
                    await viewModel.retryFetchAllData()
                }
            })
            .ignoresSafeArea()

            // 고정 타이틀 바 (항상 표시)
            HStack {
                titleView
                Spacer()
                myItemBtn
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .background(Color.white100)
        }
    }
}
