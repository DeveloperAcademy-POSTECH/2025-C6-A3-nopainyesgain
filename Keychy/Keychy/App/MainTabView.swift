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
    }
}
