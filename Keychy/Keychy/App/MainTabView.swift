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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈
            HomeTab(router: homeRouter)
                .tabItem {
                    Label("홈", systemImage: "house")
                }
                .tag(0)
            
            // 보관함
            CollectionTab(router: collectionRouter)
                .tabItem {
                    Label("보관함", systemImage: "folder")
                }
                .tag(1)
            
            // 공방
            WorkshopTab(router: workshopRouter)
                .tabItem {
                    Label("공방", systemImage: "hammer")
                }
                .tag(2)
            
            // 페스티벌
            FestivalTab(router: festivalRouter)
                .tabItem {
                    Label("페스티벌", systemImage: "flag")
                }
                .tag(3)
        }
        .tint(Color(#colorLiteral(red: 0.9999999404, green: 0.1882483959, blue: 0.3371632099, alpha: 1)))
    }
}
