//
//  MainTabView.swift
//  Keychy
//
//  Created by 길지훈 on 10/15/25.
//

import SwiftUI

/// 앱의 메인 탭 화면
///
/// 4개의 메인 탭(홈, 공방, 보관함, 페스티벌)을 관리하고
/// 딥링크 처리, 스플래시 화면, 배지 카운트 동기화 등을 담당
struct MainTabView: View {
    @State private var viewModel = MainTabViewModel()

    // MARK: - Body
    var body: some View {
        ZStack {
            mainTabView

            // 스플래시 화면
            if viewModel.showSplash {
                splashOverlay
            }
        }
        .fullScreenCover(isPresented: $viewModel.showReceiveSheet, onDismiss: {
            if viewModel.receivedPostOfficeId != nil {
                viewModel.shouldRefreshCollection = true
            }
            viewModel.receivedPostOfficeId = nil
        }) {
            receiveSheetContent
        }
        .fullScreenCover(isPresented: $viewModel.showCollectSheet, onDismiss: {
            if viewModel.collectedPostOfficeId != nil {
                viewModel.shouldRefreshCollection = true
            }
            viewModel.collectedPostOfficeId = nil
        }) {
            collectSheetContent
        }
    }
}

// MARK: - Main Tab View
extension MainTabView {
    private var mainTabView: some View {
        TabView(selection: $viewModel.selectedTab) {
            homeTab
            workshopTab
            collectionTab
            festivalTab
        }
        .tint(.main500)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear(perform: viewModel.handleAppear)
        .onChange(of: viewModel.deepLinkManager.pendingPostOfficeId, viewModel.handleDeepLinkChange)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 앱이 포그라운드로 복귀할 때 배지 카운트 동기화
            viewModel.userManager.updateBadgeCount()
        }
    }

    private var splashOverlay: some View {
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

// MARK: - Tab Views
extension MainTabView {
    private var homeTab: some View {
        HomeTab(
            router: viewModel.homeRouter,
            userManager: viewModel.userManager,
            onBackgroundLoaded: {
                DispatchQueue.main.asyncAfter(deadline: .now() + MainTabViewModel.Delay.splashAnimation) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        viewModel.showSplash = false
                    }
                }
            }
        )
        .modifier(TabItemModifier(
            image: .home,
            title: "홈",
            tag: MainTabViewModel.TabIndex.home.rawValue
        ))
    }

    private var workshopTab: some View {
        WorkshopTab(
            router: viewModel.workshopRouter,
            festivalRouter: viewModel.festivalRouter,
            festivalVM: viewModel.festivalViewModel
        )
        .modifier(TabItemModifier(
            image: .workshop,
            title: "공방",
            tag: MainTabViewModel.TabIndex.workshop.rawValue
        ))
    }

    private var collectionTab: some View {
        CollectionTab(
            router: viewModel.collectionRouter,
            shouldRefresh: $viewModel.shouldRefreshCollection
        )
        .modifier(TabItemModifier(
            image: .collection,
            title: "보관함",
            tag: MainTabViewModel.TabIndex.collection.rawValue
        ))
    }

    private var festivalTab: some View {
        FestivalTab(
            router: viewModel.festivalRouter,
            workshopRouter: viewModel.workshopRouter,
            showcaseVM: viewModel.festivalViewModel,
            onSwitchToWorkshop: { route in
                viewModel.handleSwitchToWorkshop(route)
            }
        )
        .modifier(TabItemModifier(
            image: .festival,
            title: "페스티벌",
            tag: MainTabViewModel.TabIndex.festival.rawValue
        ))
    }
}

// MARK: - Sheet Contents
extension MainTabView {
    @ViewBuilder
    private var receiveSheetContent: some View {
        if let postOfficeId = viewModel.receivedPostOfficeId {
            KeyringReceiveView(
                viewModel: viewModel.collectionViewModel,
                postOfficeId: postOfficeId
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var collectSheetContent: some View {
        if let postOfficeId = viewModel.collectedPostOfficeId {
            KeyringCollectView(
                viewModel: viewModel.collectionViewModel,
                postOfficeId: postOfficeId
            )
        } else {
            EmptyView()
        }
    }
}

// MARK: - View Modifiers
struct TabItemModifier: ViewModifier {
    let image: ImageResource
    let title: String
    let tag: Int

    func body(content: Content) -> some View {
        content
            .tabItem {
                Image(image)
                    .renderingMode(.template)
                Text(title)
            }
            .tag(tag)
    }
}
