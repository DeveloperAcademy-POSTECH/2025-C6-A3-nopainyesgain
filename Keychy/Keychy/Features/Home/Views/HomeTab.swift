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
    @State private var collectionViewModel = CollectionViewModel()
    @Bindable private var introViewModel = IntroViewModel()

    // 🚧 개발용: 알림 화면 바로 이동 (개발 완료 후 false로 변경!)
    private let debugGoToAlarm = true

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(router: router, userManager: userManager, collectionViewModel: collectionViewModel)
                .onAppear {
                    if debugGoToAlarm {
                        router.push(.alarmView)
                    }
                }
                .navigationDestination(for: HomeRoute.self) {route in
                    switch route {
                        //키링 뭉치함
                    case .bundleInventoryView:
                        BundleInventoryView(router: router, viewModel: collectionViewModel)
                    case .bundleDetailView:
                        BundleDetailView(router: router, viewModel: collectionViewModel)
                    case .bundleSelectBackgroundView:
                        BundleSelectBackgroundView(router: router, viewModel: collectionViewModel)
                    case .bundleSelectCarabinerView:
                        BundleSelectCarabinerView(router: router, viewModel: collectionViewModel)
                    case .bundleAddKeyringView:
                        BundleAddKeyringView(router: router, viewModel: collectionViewModel)
                    case .bundleNameInputView:
                        BundleNameInputView(router: router, viewModel: collectionViewModel)
                        // 재화 충전
                    case .coinCharge:
                        CoinChargeView(router: router)
                    case .myPageView:
                        MyPageView(router: router)
                    case .changeName:
                        ChangeNameView(router: router)
                    case .alarmView:
                        AlarmView()
                    case .introView:
                        IntroView(viewModel: introViewModel)
                    case .termsAndPolicy:
                        TermsWebView(router: router)
                }
            }
        }
    }
}
