//
//  HomeTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct HomeTab: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(router: router, userManager: userManager)
                .navigationDestination(for: HomeRoute.self) {route in
                    switch route {
                    case .BundleInventoryView:
                        //TODO: 라우터 논의 후 뷰모델 수정
                        BundleInventoryView(router: router, viewModel: CollectionViewModel())
                    case .BundleDetailView:
                        BundleDetailView(router: router)
                    case .BundleCreateView:
                        BundleCreateView(router: router, viewModel: CollectionViewModel())
                    case .BundleSelectBackgroundView:
                        BundleSelectBackgroundView(router: router, viewModel: CollectionViewModel())
                    case .coinCharge:
                        CoinChargeView(router: router)
                    }
                }
        }
    }
}
