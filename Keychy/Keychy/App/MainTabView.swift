//
//  ContentView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/15/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var homeRouter = NavigationRouter<HomeRoute>()
    @State private var collectionRouter = NavigationRouter<CollectionRoute>()
    @State private var workshopRouter = NavigationRouter<WorkshopRoute>()
    @State private var festivalRouter = NavigationRouter<FestivalRoute>()
    @State private var userManager = UserManager.shared
    @State private var deepLinkManager = DeepLinkManager.shared
    @State private var collectionViewModel = CollectionViewModel()

    @State private var showReceiveSheet = false
    @State private var showCollectSheet = false
    @State private var receivedPostOfficeId: String?
    @State private var collectedPostOfficeId: String?
    @State private var shouldRefreshCollection = false

    /// 스플래시 표시 여부
    @State private var showSplash: Bool = true

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // 홈
                HomeTab(
                    router: homeRouter,
                    userManager: userManager,
                    onBackgroundLoaded: {
                        // 배경이 로드되면 스플래시 페이드아웃
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
                )
                .tabItem {
                    Image("home")
                        .renderingMode(.template)
                    Text("홈")
                }
                .tag(0)

            // 공방
            WorkshopTab(router: workshopRouter)
                .tabItem {
                    Image("workshop")
                        .renderingMode(.template)
                    Text("공방")
                }
                .tag(1)

            // 보관함
            CollectionTab(router: collectionRouter, shouldRefresh: $shouldRefreshCollection)
                .tabItem {
                    Image("collection")
                        .renderingMode(.template)
                    Text("보관함")
                }
                .tag(2)

            // 페스티벌
            FestivalTab(router: festivalRouter)
                .tabItem {
                    Image("festival")
                        .renderingMode(.template)
                    Text("페스티벌")
                }
                .tag(3)
            }
            .tint(.main500)  // 선택된 아이템 색상
            .tabBarMinimizeBehavior(.onScrollDown)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    checkPendingDeepLink()
                }
            }
            .onChange(of: deepLinkManager.pendingPostOfficeId) { oldValue, newValue in
                if newValue != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        checkPendingDeepLink()
                    }
                }
            }
            .fullScreenCover(isPresented: $showReceiveSheet) {
                // 시트가 닫힐 때 새로고침 플래그 활성화
                if receivedPostOfficeId != nil {
                    shouldRefreshCollection = true
                }
                receivedPostOfficeId = nil
            } content: {
                if let postOfficeId = receivedPostOfficeId {
                    KeyringReceiveView(
                        viewModel: collectionViewModel,
                        postOfficeId: postOfficeId
                    )
                    .onDisappear {
                        receivedPostOfficeId = nil
                    }
                }
            }
            .fullScreenCover(isPresented: $showCollectSheet) {
                if collectedPostOfficeId != nil {
                    shouldRefreshCollection = true
                }
                collectedPostOfficeId = nil
            } content: {
                if let postOfficeId = collectedPostOfficeId {
                    KeyringCollectView(
                        viewModel: collectionViewModel,
                        postOfficeId: postOfficeId
                    )
                    .onDisappear {
                        collectedPostOfficeId = nil
                    }
                }
            }

            // 스플래시 화면
            if showSplash {
                ZStack {
                    // 배경색으로 전체 화면 덮기 (탭바 포함)
                    Color.white
                        .ignoresSafeArea()

                    SplashView()
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
    
    private func checkPendingDeepLink() {
        // 저장된 딥링크가 있는지 확인
        if let (postOfficeId, type) = deepLinkManager.consumePendingDeepLink() {
            print("저장된 딥링크 처리: \(postOfficeId), 타입: \(type)")
            handleDeepLink(postOfficeId: postOfficeId, type: type)
        }
    }
    
    private func handleDeepLink(postOfficeId: String, type: DeepLinkType) {
        print("키링 수신 처리 시작: \(postOfficeId)")

        selectedTab = 2  // 보관함 탭 (순서 변경으로 2번으로 이동)

        switch type {
        case .receive:
            receivedPostOfficeId = postOfficeId
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showReceiveSheet = true
            }
        case .collect:
            collectedPostOfficeId = postOfficeId
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCollectSheet = true
            }
        }
    }
}
