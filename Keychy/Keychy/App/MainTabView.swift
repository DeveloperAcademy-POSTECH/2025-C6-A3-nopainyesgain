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
    @State private var receivedKeyringId: String?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈
            HomeTab(router: homeRouter, userManager: userManager)
                .tabItem {
                    Image("home")
                        .renderingMode(.template)
                    Text("홈")
                }
                .tag(0)

            // 보관함
            CollectionTab(router: collectionRouter)
                .tabItem {
                    Image("collection")
                        .renderingMode(.template)
                    Text("보관함")
                }
                .tag(1)

            // 공방
            WorkshopTab(router: workshopRouter)
                .tabItem {
                    Image("workshop")
                        .renderingMode(.template)
                    Text("공방")
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
        .onAppear {
            checkPendingDeepLink()
        }
        .onChange(of: deepLinkManager.pendingKeyringId) { oldValue, newValue in
            if newValue != nil {
                checkPendingDeepLink()
            }
        }
        .fullScreenCover(isPresented: $showReceiveSheet) {
            if let keyringId = receivedKeyringId {
                KeyringReceiveView(
                    viewModel: collectionViewModel,
                    keyringId: keyringId
                )
                .onDisappear {
                    receivedKeyringId = nil
                }
            }
        }
        
    }
    
    private func checkPendingDeepLink() {
        // 저장된 딥링크가 있는지 확인
        if let keyringId = deepLinkManager.consumePendingDeepLink() {
            print("저장된 딥링크 처리: \(keyringId)")
            handleDeepLink(keyringId: keyringId)
        }
    }
    
    private func handleDeepLink(keyringId: String) {
        print("키링 수신 처리 시작: \(keyringId)")
        
        selectedTab = 1
        
        receivedKeyringId = keyringId
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showReceiveSheet = true
        }
    }
}
//keychy://receive?keyringId=QK173zLjUXMlwII228Mn
