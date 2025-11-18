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

    let categories = ["키링", "카라비너", "이펙트", "배경"]

    /// WorkshopTab에서 생성된 viewModel을 받아서 사용
    init(router: NavigationRouter<WorkshopRoute>, viewModel: WorkshopViewModel) {
        self.router = router
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 상단 배너 (코인 버튼 + 타이틀)
                topBannerSection
                    .frame(height: 150)

                Spacer()
                    .frame(height: 20)

                // 내 아이템 섹션
                CurrentUsedSection

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
                Image("WorkshopBack")
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

    let viewModel = WorkshopViewModel(userManager: userManager)

    return WorkshopView(router: NavigationRouter<WorkshopRoute>(), viewModel: viewModel)
        .environment(userManager)
}
