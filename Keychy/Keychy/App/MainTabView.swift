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
    @State private var festivalViewModel = Showcase25BoardViewModel()

    @State private var showReceiveSheet = false
    @State private var showCollectSheet = false
    @State private var receivedPostOfficeId: String?
    @State private var collectedPostOfficeId: String?
    @State private var shouldRefreshCollection = false

    /// 스플래시 표시 여부
    @State private var showSplash: Bool = true

    var body: some View {
        ZStack {
            mainTabView
            
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
        .fullScreenCover(isPresented: $showReceiveSheet, onDismiss: handleReceiveDismiss) {
            receiveSheetContent
        }
        .fullScreenCover(isPresented: $showCollectSheet, onDismiss: handleCollectDismiss) {
            collectSheetContent
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            homeTab
            workshopTab
            collectionTab
            festivalTab
        }
        .tint(.main500)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear(perform: handleAppear)
        .onChange(of: deepLinkManager.pendingPostOfficeId, handleDeepLinkChange)
    }
    
    private var homeTab: some View {
        HomeTab(
            router: homeRouter,
            userManager: userManager,
            onBackgroundLoaded: {
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
    }
    
    private var workshopTab: some View {
        WorkshopTab(
            router: workshopRouter,
            festivalRouter: festivalRouter,
            festivalVM: festivalViewModel
        )
        .tabItem {
            Image("workshop")
                .renderingMode(.template)
            Text("공방")
        }
        .tag(1)
    }
    
    private var collectionTab: some View {
        CollectionTab(router: collectionRouter, shouldRefresh: $shouldRefreshCollection)
            .tabItem {
                Image("collection")
                    .renderingMode(.template)
                Text("보관함")
            }
            .tag(2)
    }
    
    private var festivalTab: some View {
        FestivalTab(
            router: festivalRouter,
            workshopRouter: workshopRouter,
            showcaseVM: festivalViewModel,
            onSwitchToWorkshop: { route in
                self.handleSwitchToWorkshop(route)
            }
        )
        .tabItem {
            Image("festival")
                .renderingMode(.template)
            Text("페스티벌")
        }
        .tag(3)
    }
    
    @ViewBuilder
    private var receiveSheetContent: some View {
        if let postOfficeId = receivedPostOfficeId {
            KeyringReceiveView(
                viewModel: collectionViewModel,
                postOfficeId: postOfficeId
            )
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var collectSheetContent: some View {
        if let postOfficeId = collectedPostOfficeId {
            KeyringCollectView(
                viewModel: collectionViewModel,
                postOfficeId: postOfficeId
            )
        } else {
            EmptyView()
        }
    }
    
    private func handleAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            checkPendingDeepLink()
        }
    }
    
    private func handleDeepLinkChange(oldValue: String?, newValue: String?) {
        if newValue != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                checkPendingDeepLink()
            }
        }
    }
    
    private func handleSwitchToWorkshop(_ route: WorkshopRoute) {
        // Festival에서 Workshop으로 갈 때 플래그 설정
        festivalViewModel.isFromFestivalTab = true
        festivalViewModel.onKeyringCompleteFromFestival = { router in
            // 키링 완료 후 Workshop navigation stack 초기화
            router.reset()
            
            // Festival 탭으로 복귀
            self.selectedTab = 3
            
            // 플래그 초기화
            self.festivalViewModel.isFromFestivalTab = false
        }
        
        // 탭을 공방으로 전환
        selectedTab = 1
        // 약간의 딜레이 후 라우팅 (탭 전환 애니메이션 완료 대기)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.workshopRouter.push(route)
        }
    }
    
    private func handleReceiveDismiss() {
        if receivedPostOfficeId != nil {
            shouldRefreshCollection = true
        }
        receivedPostOfficeId = nil
    }
    
    private func handleCollectDismiss() {
        if collectedPostOfficeId != nil {
            shouldRefreshCollection = true
        }
        collectedPostOfficeId = nil
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

        switch type {
        case .receive:
            selectedTab = 2  // 보관함 탭
            receivedPostOfficeId = postOfficeId
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showReceiveSheet = true
            }
        case .collect:
            selectedTab = 2  // 보관함 탭
            collectedPostOfficeId = postOfficeId
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCollectSheet = true
            }
        case .notification:
            selectedTab = 0  // 홈 탭
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                homeRouter.push(.notificationGiftView(postOfficeId: postOfficeId))
            }
        }
    }
}
