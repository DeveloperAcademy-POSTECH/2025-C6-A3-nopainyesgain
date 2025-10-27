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
            Button("다람쥐 헌 쳇바퀴에 타고파") {
                router.push(.BundleInventoryView)
            }
            Button("재화 충전하기") {
                router.push(.coinCharge)
            }
        }
        .navigationTitle("Home")
    }
}
