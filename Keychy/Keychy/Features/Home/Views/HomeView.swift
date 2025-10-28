//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    
    var body: some View {
        VStack {
            if userManager.isLoaded {
                VStack(spacing: 8) {
                    Text("환영합니다 \(userManager.userNickname)님")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("UID: \(userManager.userUID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical)
            } else {
                ProgressView("사용자 정보 로딩 중...")
            }
            
            Button("다람쥐 헌 쳇바퀴에 타고파") {
                router.push(.bundleInventoryView)
            }
            .typography(.suit15R)
            
            
            Button("재화 충전하기") {
                router.push(.coinCharge)
            }
        }
        .navigationTitle("Home")
    }
}
