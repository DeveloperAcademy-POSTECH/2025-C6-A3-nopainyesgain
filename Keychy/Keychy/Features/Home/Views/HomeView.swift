//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    
    var body: some View {
        VStack {
            Button("뭉치함으로 가기") {
                router.push(.BundleInventoryView)
            }
            .font(.h1)
        }
        .navigationBarTitle("Home")
    }
}
